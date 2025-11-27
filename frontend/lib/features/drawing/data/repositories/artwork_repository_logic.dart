import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/data/datasources/artwork_local_datasource.dart';
import 'package:flutter_frontend/features/drawing/data/models/artwork_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';

class ArtworkRepositoryLogic implements ArtworkRepositoryInterface {
  final ArtworkLocalDatasource _localDatasource;

  ArtworkRepositoryLogic({required ArtworkLocalDatasource localDatasource})
    : _localDatasource = localDatasource;

  @override
  Future<void> deleteArtwork(String id) {
    return _localDatasource.deleteArtwork(id);
  }

  @override
  ArtworkEntity? fetchArtwork(String id) {
    return _localDatasource.fetchArtwork(id)?.toEntity();
  }

  @override
  List<ArtworkEntity> fetchAllArtworks() {
    return _localDatasource.fetchAllArtworks().map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveArtwork(ArtworkEntity artwork) {
    final String id = artwork.id;
    return _localDatasource.saveArtwork(id, ArtworkModel.fromEntity(artwork));
  }

  @override
  Listenable get listenable => _localDatasource.listenable;
}