import 'dart:typed_data';

import 'package:flutter_frontend/features/drawing/domain/entities/image_entity.dart';
import 'package:flutter_frontend/services/dio_client.dart';
import 'package:hive/hive.dart';

part 'image_model.g.dart';

@HiveType(typeId: 2)
class ImageModel {

  @HiveField(0)
  final String path;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final int? size;

  @HiveField(3)
  final String? orig_name;

  @HiveField(4)
  final String? mime_type;

  @HiveField(5)
  final bool is_stream;

  @HiveField(6)
  final dynamic meta;

  @HiveField(7)
  late final Uint8List? content;

  ImageModel({
    required this.path,
    required this.url,
    this.size,
    this.orig_name,
    this.mime_type,
    required this.is_stream,
    this.meta,
    this.content,
  });

  // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'path': path,
      'url': url,
      'size':size,
      'orig_name': orig_name,
      'mime_type': mime_type,
      'is_stream': is_stream,
      'meta': meta,
    };
  }

  // converts server objects to flutter models
  factory ImageModel.fromServerObject(Map<String, dynamic> jsonStencil) {
    return ImageModel(
      path: jsonStencil['path'],
      url: jsonStencil['url'],
      size: jsonStencil['size'],
      orig_name: jsonStencil['orig_name'],
      mime_type: jsonStencil['mime_type'],
      is_stream: jsonStencil['is_stream'],
      meta: jsonStencil['meta'],
    );
  }

  Future<void> loadContent() async {
    final response = await dio.sendRequest<Uint8List>('GET', url);
    content = response.data;
  }

  ImageEntity toEntity() {
    return ImageEntity(
      path: path,
      url: url,
      size: size,
      orig_name: orig_name,
      mime_type: mime_type,
      is_stream: is_stream,
      meta: meta,
      content: content,
    );
  }

  factory ImageModel.fromEntity(ImageEntity entity) {
    return ImageModel(
      path: entity.path,
      url: entity.url,
      size: entity.size,
      orig_name: entity.orig_name,
      mime_type: entity.mime_type,
      is_stream: entity.is_stream,
      meta: entity.meta,
      content: entity.content,
    );
  }
}