import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';
import 'package:uuid/uuid.dart';

class ArtworkEntity {
  String id;
  String? serverId; // server assigned id, null until object is synced with the server
  String title;
  String description;
  List<StencilEntity> stencilList;
  List<StrokeEntity> strokeList;

  ArtworkEntity ({
    String? id,
    this.serverId,
    required this.title,
    required this.description,
    required this.stencilList,
    required this.strokeList
  }) : id = id ?? const Uuid().v4();
}