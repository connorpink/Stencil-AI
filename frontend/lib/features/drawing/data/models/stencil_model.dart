import 'package:flutter_frontend/features/drawing/data/models/image_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:hive/hive.dart';

part 'stencil_model.g.dart';

@HiveType(typeId: 1)
class StencilModel extends HiveObject {
  @HiveField(0)
  final String prompt;

  @HiveField(1)
  final List<ImageModel> imageList;

  StencilModel({
    required this.prompt,
    required this.imageList
  });

  // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'prompt': prompt,
      'imageList': imageList,
    };
  }
  
  // converts server objects to flutter models
  factory StencilModel.fromServerObject(Map<String, dynamic> jsonStencil) {
    return StencilModel(
      prompt: jsonStencil['prompt'],
      imageList: (jsonStencil['imageList'] as List)
        .map((image) => ImageModel.fromServerObject(image as Map<String, dynamic>))
        .toList(),
    );
  }

  StencilEntity toEntity() {
    return StencilEntity(
      prompt: prompt,
      imageList: imageList.map((image) => image.toEntity()).toList(),
    );
  }

  factory StencilModel.fromEntity(StencilEntity entity) {
    return StencilModel(
      prompt: entity.prompt,
      imageList: entity.imageList.map((image) => ImageModel.fromEntity(image)).toList(),
    );
  }
}