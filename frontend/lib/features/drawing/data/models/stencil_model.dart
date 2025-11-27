import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:hive/hive.dart';

part 'stencil_model.g.dart';

@HiveType(typeId: 1)
class StencilModel {

  @HiveField(0)
  final String name;

  @HiveField(1)
  final Uint8List imageData;

  StencilModel({
    required this.name,
    required this.imageData,
  });

  factory StencilModel.fromJson(Map<String, dynamic> json) {
    return StencilModel(
      name: json['name'],
      imageData: base64Decode(json['imageData'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageData': base64Encode(imageData)
    };
  }

  StencilEntity toEntity() {
    return StencilEntity(
      name: name,
      imageData: imageData,
    );
  }

  factory StencilModel.fromEntity(StencilEntity entity) {
    return StencilModel(
      name: entity.name, 
      imageData: entity.imageData
    );
  }
}