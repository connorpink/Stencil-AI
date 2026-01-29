import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/data/models/image_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:hive/hive.dart';

part 'stencil_model.g.dart';

@HiveType(typeId: 1)
class StencilModel extends HiveObject {
  @HiveField(0)
  final String prompt;

  @HiveField(1)
  final int preferredImageIndex;

  @HiveField(2)
  final List<ImageModel> imageList;

  @HiveField(3)
  final List<double>? position;

  @HiveField(4)
  final double? rotation;

  @HiveField(5)
  final double? scale;

  StencilModel({
    required this.prompt,
    required this.preferredImageIndex,
    required this.imageList,
    this.position,
    this.rotation,
    this.scale,
  });

  // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'prompt': prompt,
      'preferredImageIndex': preferredImageIndex,
      'imageList': imageList,
      'position': position,
      'rotation': rotation,
      'scale': scale,
    };
  }
  
  // converts server objects to flutter models
  factory StencilModel.fromServerObject(List<Uint8List> imageContentList, Map<String, dynamic> jsonStencil) {
    return StencilModel(
      prompt: jsonStencil['prompt'],
      preferredImageIndex: 0,
      imageList: (jsonStencil['imageList'] as List)
        .asMap().entries.map((entry) {
          int index = entry.key;
          return ImageModel.fromServerObject(imageContentList[index], entry.value as Map<String, dynamic>);
        })
        .toList(),
      position: jsonStencil['position'] as List<double>?,
      rotation: jsonStencil['rotation'] as double?,
      scale: jsonStencil['scale'] as double?,
    );
  }

  List<Uint8List> packageImageContent() {
    return imageList.map((image) {
      return image.packageImageContent();
    }).toList();
  }

  StencilEntity toEntity() {
    return StencilEntity(
      prompt: prompt,
      preferredImageIndex: preferredImageIndex,
      imageList: imageList.map((image) => image.toEntity()).toList(),
      position: position != null ? Offset(position![0], position![1]) : null,
      rotation: rotation,
      scale: scale,
    );
  }

  factory StencilModel.fromEntity(StencilEntity entity) {
    return StencilModel(
      prompt: entity.prompt,
      preferredImageIndex: entity.preferredImageIndex,
      imageList: entity.imageList.map((image) => ImageModel.fromEntity(image)).toList(),
      position: entity.position != null ? [entity.position!.dx, entity.position!.dy] : null,
      rotation: entity.rotation,
      scale: entity.scale,
    );
  }
}