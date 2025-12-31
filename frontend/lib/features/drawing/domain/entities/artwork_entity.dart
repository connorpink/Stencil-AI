import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';

class ArtworkEntity {
  String id;
  String? serverId; // server assigned id, null until object is synced with the server
  String title;
  String prompt;
  List<StencilEntity> stencilList;
  List<StrokeEntity> strokeList;
  DateTime updatedAt;

  ArtworkEntity ({
    required this.id,
    this.serverId,
    required this.title,
    required this.prompt,
    required this.stencilList,
    required this.strokeList,
    required this.updatedAt,
  });
}