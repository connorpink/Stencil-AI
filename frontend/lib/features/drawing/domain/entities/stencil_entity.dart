import 'package:flutter/animation.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/image_entity.dart';

class StencilEntity {
  final String prompt;
  int preferredImageIndex;
  final List<ImageEntity> imageList;
  Offset? position;
  double? rotation;
  double? scale;

  StencilEntity({
    required this.prompt,
    required this.preferredImageIndex,
    required this.imageList,
    this.position,
    this.rotation,
    this.scale,
  });

  StencilEntity copyWith({
    int? preferredImageIndex,
    Offset? position,
    double? rotation,
    double? scale,
  }) {
    return StencilEntity(
      prompt: prompt,
      preferredImageIndex: preferredImageIndex ?? this.preferredImageIndex,
      imageList: imageList,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}