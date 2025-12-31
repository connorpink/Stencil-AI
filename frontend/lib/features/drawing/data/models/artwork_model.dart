import 'package:flutter_frontend/features/drawing/data/models/stencil_model.dart';
import 'package:flutter_frontend/features/drawing/data/models/stroke_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:hive/hive.dart';

part 'artwork_model.g.dart';

@HiveType(typeId: 0)
class ArtworkModel {

  @HiveField(0)
  final String id; // assigned by the client

  @HiveField(1)
  final String? serverId; // server assigned id, null until object is synced with the server

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String prompt;

  @HiveField(4)
  final List<StencilModel> stencilList;

  @HiveField(5)
  final List<StrokeModel> strokeList;

  @HiveField(6)
  final DateTime updatedAt;

  ArtworkModel({
    required this.id,
    this.serverId,
    required this.title,
    required this.prompt,
    required this.stencilList,
    required this.strokeList,
    required this.updatedAt,
  });

  // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'id': serverId,
      'title': title,
      'prompt': prompt,
      'stencilList': stencilList.map((stencil) => stencil.toServerObject()).toList(),
      'strokeList': strokeList.map((stroke) => stroke.toServerObject()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // convert server objects to flutter models
  factory ArtworkModel.fromServerObject(String clientId, Map<String, dynamic> jsonArtwork) {
    return ArtworkModel(
      id: clientId,
      serverId: jsonArtwork['id'],
      title: jsonArtwork['title'],
      prompt: jsonArtwork['prompt'],
      stencilList: (jsonArtwork['stencilList'] as List)
        .map((stencil) => StencilModel.fromServerObject(stencil as Map<String, dynamic>))
        .toList(),
      strokeList: (jsonArtwork['strokeList'] as List)
        .map((stroke) => StrokeModel.fromServerObject(stroke as Map<String, dynamic>))
        .toList(),
      updatedAt: DateTime.parse(jsonArtwork['updatedAt']),
    );
  }

  ArtworkEntity toEntity() {
    return ArtworkEntity(
      id: id,  
      serverId: serverId,
      title: title,
      prompt: prompt,
      stencilList: stencilList.map((stencil) => stencil.toEntity()).toList(),
      strokeList: strokeList.map((stroke) => stroke.toEntity()).toList(),
      updatedAt: updatedAt,
    );
  }

  factory ArtworkModel.fromEntity(ArtworkEntity entity) {
    return ArtworkModel(
      id: entity.id,
      serverId: entity.serverId,
      title: entity.title,
      prompt: entity.prompt,
      stencilList: entity.stencilList.map((stencil) => StencilModel.fromEntity(stencil)).toList(),
      strokeList: entity.strokeList.map((stroke) => StrokeModel.fromEntity(stroke)).toList(),
      updatedAt: entity.updatedAt,
    );
  }
}