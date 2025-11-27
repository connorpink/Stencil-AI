import 'dart:ui';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';
import 'package:hive/hive.dart';
import 'offset_model.dart';

part 'stroke_model.g.dart';

@HiveType(typeId: 2)
class StrokeModel extends HiveObject{
  @HiveField(0)
  final List<OffsetModel> points;

  @HiveField(1)
  final int color;

  @HiveField(2)
  final double brushSize;

  StrokeModel({
    required this.points,
    required this.color,
    required this.brushSize,
  });

  StrokeEntity toEntity() {
    return StrokeEntity(
      points: points.map((p) => p.toEntity()).toList(), 
      color: Color(color),
      brushSize: brushSize,
    );
  }

  factory StrokeModel.fromEntity(StrokeEntity entity) {
    return StrokeModel(
      points: entity.points.map((p) => OffsetModel.fromEntity(p)).toList(),
      color: entity.color.toARGB32(),
      brushSize: entity.brushSize,
    );
  }
}