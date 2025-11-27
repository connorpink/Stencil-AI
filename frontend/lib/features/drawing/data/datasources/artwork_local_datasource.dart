import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/data/models/artwork_model.dart';
import 'package:hive_flutter/adapters.dart';

class ArtworkLocalDatasource {
  final Box<ArtworkModel> _box;

  ArtworkLocalDatasource(this._box);

  List<ArtworkModel> fetchAllArtworks() => _box.values.toList();

  ArtworkModel? fetchArtwork(String id) => _box.get(id);

  Future<void> saveArtwork(String id, ArtworkModel artwork) => _box.put(id, artwork);

  Future<void> deleteArtwork(String id) => _box.delete(id);

  Listenable get listenable => _box.listenable();
}