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
    
    final List<ArtworkModel> artworkList = _localDatasource.fetchAllArtworks();

    // only check with the server for artworks if requested by the client
    if (checkServer) {
      dio.sendRequest<Future<List<ArtworkModel>>>(
        'GET', 
        '/artwork/fetchAll',
        responseProcessor: (serverObjectList) => findNewObjects(artworkList, serverObjectList)
      )
      .then((response) async {
        final List<ArtworkModel> serverArtworkList = await response.data;
        for (ArtworkModel serverArtwork in serverArtworkList) {
          _localDatasource.saveArtwork(serverArtwork.id, serverArtwork);
        }
      })
      .catchError((error){
        appLogger.e('Server failed to fetch list of artworks from the server \nError: $error');
      });
    }

    return artworkList.map((artwork) { return artwork.toEntity(); }).toList();
  }

  @override
  Future<ArtworkEntity> fetchArtwork(String id) async {

    late final ArtworkModel? localArtwork;

    // fetch the artwork locally
    try { localArtwork = _localDatasource.fetchArtwork(id); }
    catch (error) { appLogger.e("local storage failed to save artwork \nError: $error"); }

    if (localArtwork == null) {
      appLogger.e('Local storage failed to find artwork with id: $id');
      throw Exception('Local storage failed to find artwork, please try again');
    }

    // if artwork doesn't have an assigned id, throw a warning and return the artwork
    if (localArtwork.serverId == null) { 
      appLogger.w('No serverId assigned to artwork with Id: $id');
      return localArtwork.toEntity();
    }

    // get a grid of all images associated with artwork so we dont need to redownload them
    final List<List<Uint8List>> imageContentGrid = localArtwork.packageImageContent();

    // fetch the artwork globally
    final ApiResponse<ArtworkModel> response = await dio.sendRequest<ArtworkModel>(
      'GET',
      '/artwork/fetch/$id', 
      responseProcessor: (serverObject) => ArtworkModel.fromServerObject(localArtwork!.serverId!, imageContentGrid, serverObject)
    );

    final ArtworkModel? serverArtwork = response.data;
      
    if (serverArtwork == null) {
      appLogger.w("Server didn't return an artwork for id: ${localArtwork.serverId}");
    }
    else if (serverArtwork.updatedAt.isAfter(localArtwork.updatedAt)) {
      _localDatasource.saveArtwork(id, serverArtwork);
      return serverArtwork.toEntity();
    }

    return localArtwork.toEntity();
  }

  @override
  Future<ArtworkEntity> createArtwork(String prompt) async {

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
    catch (error) {
      appLogger.e("Artwork repository failed to receive a valid artworkModel from dio \nError: $error");
      appLogger.w("Creating a default artworkModel for the user to draw with");
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
  }

  @override
  void saveArtwork(ArtworkEntity artwork) {

    // convert artworkEntity to models and serverObjects
    final ArtworkModel artworkModel = ArtworkModel.fromEntity(artwork);
    final artworkServerObject = artworkModel.toServerObject();

    // save artwork locally
    try {
      _localDatasource.saveArtwork(artworkModel.id, artworkModel); 
    }
    catch (error) {
      appLogger.e("local storage failed to save artwork \nError: $error");
      throw Exception("Failed to save artwork to the local storage, please try again");
    }

    // attempt to save the artwork globally
    dio.sendRequest<bool>(
      'POST',
      '/artwork/save',
      data: { 'artwork': artworkServerObject },
    )
    .then((response) {
      if (response.data == false) { appLogger.w("Servers failed to save the artwork without an error. Server side storage limits may have been reached"); }
    })
    .catchError((error) {
      appLogger.w('Server failed to save artwork with serverId: ${artwork.serverId} \nError: $error');
    });

    return;
  }

  @override
  void deleteArtwork(ArtworkEntity artwork) {

    // delete artwork locally
    try { 
      _localDatasource.deleteArtwork(artwork.id); 
    }
    catch (error) { 
      appLogger.e('local storage failed to delete artwork object with Id: ${artwork.id} \n Error: $error');
      throw Exception('Failed to delete artwork from the local storage, please try again');
    }

    if(artwork.serverId == null) {
      appLogger.w('no serverId attached to deleted artwork object');
      return;
    }

    // attempt to delete artwork globally
    dio.sendRequest<bool>(
      'POST',
      '/artwork/delete',
      data: { 'id': artwork.serverId }
    )
    .then((ApiResponse<bool> response) {
      if (response.data == false) { appLogger.w("Servers failed to delete the artwork without an error, The artwork object likely doesn't exist server side."); }
    })
    .catchError((error){
      appLogger.w('Server failed to delete artwork object with Id: ${artwork.serverId} \nError: $error');
    });

    return;
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