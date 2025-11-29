import 'package:flutter_frontend/features/drawing/data/models/stencil_model.dart';
import 'package:flutter_frontend/features/drawing/data/models/stroke_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:hive/hive.dart';

part 'artwork_model.g.dart';

@HiveType(typeId: 0)
class ArtworkModel {

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? serverId; // server assigned id, null until object is synced with the server

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final List<StencilModel> stencilList;

  @HiveField(5)
  final List<StrokeModel> strokeList;

  ArtworkModel({
    required this.id,
    this.serverId,
    required this.title,
    required this.description,
    required this.stencilList,
    required this.strokeList
  });

  ArtworkEntity toEntity() {
    return ArtworkEntity(
      id: id,  
      serverId: serverId,
      title: title,
      description: description,
      stencilList: stencilList.map((stencil) => stencil.toEntity()).toList(),
      strokeList: strokeList.map((stroke) => stroke.toEntity()).toList()
    );
  }

  factory ArtworkModel.fromEntity(ArtworkEntity entity) {
    return ArtworkModel(
      id: entity.id,
      serverId: entity.serverId,
      title: entity.title,
      description: entity.description,
      stencilList: entity.stencilList.map((stencil) => StencilModel.fromEntity(stencil)).toList(),
      strokeList: entity.strokeList.map((stroke) => StrokeModel.fromEntity(stroke)).toList()
    );
  }
}