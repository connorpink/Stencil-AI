import 'package:flutter/animation.dart';

class StrokeEntity {
  final List<Offset> pointList;
  final Color color;
  final double brushSize;

  StrokeEntity({
    required this.pointList,
    required this.color,
    required this.brushSize,
  });
}