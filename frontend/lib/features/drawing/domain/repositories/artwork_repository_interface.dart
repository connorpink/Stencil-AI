import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';

abstract class ArtworkRepositoryInterface {
  List<ArtworkEntity> fetchAllArtworks({bool checkServer = false}); // asynchronously updated from the server
  Future<ArtworkEntity> fetchArtwork(String id); // synchronously fetched from the server before returning
  Future<ArtworkEntity> createArtwork(String prompt); // synchronously collected from the server before returning
  void saveArtwork(ArtworkEntity artwork); // asynchronously sent to the server
  void deleteArtwork(ArtworkEntity artwork); // asynchronously sent to the server
  Listenable get listenable;
}