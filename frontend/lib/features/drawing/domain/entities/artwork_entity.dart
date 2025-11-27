import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';

class ArtworkEntity {
  String id;
  String title;
  String description;
  List<StencilEntity> stencilList;
  List<StrokeEntity> strokeList;

  ArtworkEntity ({
    required this.id,
    required this.title,
    required this.description,
    required this.stencilList,
    required this.strokeList
  });
}