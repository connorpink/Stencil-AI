import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';

abstract class ArtworkRepositoryInterface {
  List<ArtworkEntity> fetchAllArtworks();
  ArtworkEntity? fetchArtwork(String id);
  Future<void> saveArtwork(ArtworkEntity artwork);
  Future<void> deleteArtwork(String id);
  Listenable get listenable;
}