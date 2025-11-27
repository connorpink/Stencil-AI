import 'package:flutter/animation.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/offset_entity.dart';

class StrokeEntity {
  final List<OffsetEntity> points;
  final Color color;
  final double brushSize;

  StrokeEntity({
    required this.points,
    required this.color,
    required this.brushSize,
  });

  List<Offset> get offsetPoints => points.map((element) => element.toOffset()).toList();

  factory StrokeEntity.fromOffset({
    required List<Offset> offsets,
    required Color color,
    required double brushSize,
  }) {
    return StrokeEntity(
      points: offsets.map((entity) => OffsetEntity.fromOffset(entity)).toList(),
      color: color,
      brushSize: brushSize,
    );
  }
}