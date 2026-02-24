import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/data/datasources/artwork_local_datasource.dart';
import 'package:flutter_frontend/features/drawing/data/models/artwork_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/services/dio_client.dart';
import 'package:flutter_frontend/services/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ArtworkRepositoryLogic implements ArtworkRepositoryInterface {
  final _uuid = const Uuid();
  final ArtworkLocalDatasource _localDatasource;

  ArtworkRepositoryLogic({required ArtworkLocalDatasource localDatasource})
    : _localDatasource = localDatasource;

  // default error handler for all functions inside the repository
  Future<T> _defaultErrorHandler<T>( String functionName, Future<T> Function() request) async {
    try { return await request(); }
    on DioException catch(_) { rethrow; } // If it was a DioException dio would have already logged it
    catch (error) {
      appLogger.e("artwork_repository.$functionName ran into an unexpected error", error: error);
      rethrow;
    }
  }

  @override
  List<ArtworkEntity> fetchAllArtworks({bool checkServer = false}) {

    // this function takes a list of ArtworkModels (fetched from _localDatasource) and a list of server objects
    // returns a list of server objects that either dont exist in _localDatasource or are a newer version of the _localDatasource version of their objects
    Future<List<ArtworkModel>> findNewObjects(List<ArtworkModel> artworkList, List<Map<String, dynamic>> serverObjectList) async {

      // this is the list that will be returned at the end
      List<ArtworkModel> completeArtworkList = [];
      Future.wait(serverObjectList.map((serverObject) async {

        // check if the serverObject already exists inside artwork list
        bool matchFound = false;
        for (ArtworkModel artwork in artworkList){

          // check if the ids match
          if (serverObject['id'] == artwork.serverId) {
            final List<List<Uint8List>> imageContentGrid = artwork.packageImageContent();
            final serverArtwork = ArtworkModel.fromServerObject(artwork.id, imageContentGrid, serverObject);
            
            // check what artwork is the most up to date
            if (serverArtwork.updatedAt.isAfter(artwork.updatedAt)) {
              completeArtworkList.add(serverArtwork);
            }

            // stop comparing and move onto the next server object
            matchFound = true;
            break;
          }
        }

        if (!matchFound) {
          final List<List<Uint8List>> imageContentGrid = await _setupImageContentGridUsingServer(serverObject);
          final ArtworkModel serverArtwork = ArtworkModel.fromServerObject(_uuid.v4(), imageContentGrid, serverObject);
          completeArtworkList.add(serverArtwork);
        }
      }));

      return completeArtworkList;
    }

    Future<void> checkServerForAdditionalArtworks(List<ArtworkModel> artworkList) async {
      return _defaultErrorHandler('fetchAllArtworks', () async {
        
        final response = await dio.sendRequest<Future<List<ArtworkModel>>>(
          'GET', 
          '/artwork/fetchAll',
          responseProcessor: (serverObjectList) { 
            return findNewObjects(artworkList, serverObjectList);
          }
        );

        final List<ArtworkModel> newArtworkList = await response.data;
        for (ArtworkModel serverArtwork in newArtworkList) {
          _localDatasource.saveArtwork(serverArtwork.id, serverArtwork);
        }

      });
    }
    
    final List<ArtworkModel> artworkList = _localDatasource.fetchAllArtworks();
    if (checkServer) { checkServerForAdditionalArtworks(artworkList); } // update from the server if necessary
    return artworkList.map((artwork) { return artwork.toEntity(); }).toList();
  }

  @override
  Future<ArtworkEntity> fetchArtwork(String id) async {
    return _defaultErrorHandler('fetchArtwork', () async {

      final ArtworkModel? localArtwork = _localDatasource.fetchArtwork(id);
      if (localArtwork == null ) { throw Exception("artwork_repository.fetchArtwork failed, id provided was not associated with any artworks found in local storage: $id"); }

      // if artwork doesn't have an assigned id, throw a warning and return the artwork
      if (localArtwork.serverId == null) {
        appLogger.w('No serverId assigned to artwork with Id: $id');
        return localArtwork.toEntity();
      }

      // package all images associated with the artwork so they arn't  redownloaded
      final List<List<Uint8List>> imageContentGrid = localArtwork.packageImageContent();

      // fetch the artwork globally
      late final ApiResponse<ArtworkModel> response;
      try {
        response = await dio.sendRequest<ArtworkModel>(
          'GET',
          '/artwork/fetch/$id', 
          responseProcessor: (serverObject) => ArtworkModel.fromServerObject(localArtwork.serverId!, imageContentGrid, serverObject)
        );
      }
      on DioException catch(_) {
        return localArtwork.toEntity();
      }

      final ArtworkModel serverArtwork = response.data;

      if (serverArtwork.updatedAt.isAfter(localArtwork.updatedAt)) {
        _localDatasource.saveArtwork(id, serverArtwork);
        return serverArtwork.toEntity();
      }
      else {
        return localArtwork.toEntity();
      }

    });
  }

  @override
  Future<ArtworkEntity> createArtwork(String prompt) async {
    return _defaultErrorHandler("createArtwork", () async {

      // create an id that client side artwork objects will be recognized by
      final String clientId = _uuid.v4();
      late final ArtworkModel newArtwork;

      try {
        final response = await dio.sendRequest<Future<ArtworkModel>>(
          'POST',
          '/artwork/create',
          data: {'title': 'new artwork', 'prompt': prompt},
          responseProcessor: (serverObject) {
            return _setupImageContentGridUsingServer(serverObject)
            .then((imageContentGrid){
              return ArtworkModel.fromServerObject(clientId, imageContentGrid, serverObject);
            });
          },
        );
        newArtwork = await response.data;
      }
      on DioException catch(_) {
        newArtwork = ArtworkModel(
          id: clientId,
          title: "Unsaved Artwork",
          prompt: prompt, 
          stencilList: [],
          strokeList: [],
          updatedAt: DateTime.now(),
        );
      }
      
      _localDatasource.saveArtwork(clientId, newArtwork);
      
      return newArtwork.toEntity();

    });
  }

  @override
  Future<void> saveArtwork(ArtworkEntity artwork) async {
    return _defaultErrorHandler("saveArtwork", () async {

      // convert artworkEntity to models and serverObjects
      final ArtworkModel artworkModel = ArtworkModel.fromEntity(artwork);
      final artworkServerObject = artworkModel.toServerObject();

      // save artwork locally
      _localDatasource.saveArtwork(artworkModel.id, artworkModel); 

      // attempt to save the artwork globally
      await dio.sendRequest<bool>(
        'POST',
        '/artwork/save',
        data: { 'artwork': artworkServerObject },
      );

      return;

    });
  }

  @override
  Future<void> deleteArtwork(ArtworkEntity artwork) {
    return _defaultErrorHandler("deleteArtwork", () async {

      _localDatasource.deleteArtwork(artwork.id);

      if(artwork.serverId == null) {
        appLogger.w('no serverId was attached to the deleted artwork object');
        return;
      }

      // delete the artwork globally
      await dio.sendRequest(
        'POST',
        '/artwork/delete',
        data: { 'id': artwork.serverId }
      );

      return;

    });
  }

  @override
  Listenable get listenable => _localDatasource.listenable;

  //function for local use only
  Future<List<List<Uint8List>>> _setupImageContentGridUsingServer(Map<String, dynamic> jsonArtwork) async {
    
    return Future.wait(
      (jsonArtwork['stencilList'] as List).map((jsonStencil) async {

        return Future.wait(
          (jsonStencil['imageList'] as List).map((jsonImage) async {
            
            final String url = jsonImage['url'];
            try {
              final response = await http.get(Uri.parse(url));
              if (response.statusCode == 200) { return response.bodyBytes; }
              else { throw Exception('Failed to load image: ${response.statusCode}'); }
            } 
            catch (error) {
              throw Exception('http request: $url returned: $error');
            }
          }).toList());
      }).toList()
    );
  }
}