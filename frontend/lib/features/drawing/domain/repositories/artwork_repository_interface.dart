import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';

abstract class ArtworkRepositoryInterface {
  List<ArtworkEntity> fetchAllArtworks({bool checkServer = false}); // asynchronously updated from the server 
  Future<ArtworkEntity> fetchArtwork(String id);
  Future<ArtworkEntity> createArtwork(String prompt);
  Future<void> saveArtwork(ArtworkEntity artwork);
  Future<void> deleteArtwork(ArtworkEntity artwork);
  Listenable get listenable;
}