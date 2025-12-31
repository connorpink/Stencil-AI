import 'package:flutter_frontend/features/drawing/domain/entities/image_entity.dart';

class StencilEntity {
  final String prompt;
  final List<ImageEntity> imageList;

  StencilEntity({
    required this.prompt,
    required this.imageList,
  });
}