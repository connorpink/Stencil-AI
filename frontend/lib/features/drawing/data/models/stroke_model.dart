import 'dart:ui';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';
import 'package:hive/hive.dart';

part 'stroke_model.g.dart';

@HiveType(typeId: 3)
class StrokeModel extends HiveObject{
  @HiveField(0)
  final List<List<double>> pointList; // List of points, points are a list of 2 doubles representing grid coordinates [x, y]

  @HiveField(1)
  final int color;

  @HiveField(2)
  final double brushSize;

  StrokeModel({
    required this.pointList,
    required this.color,
    required this.brushSize,
  });

  // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'pointList': pointList,
      'color': color,
      'brushSize': brushSize,
    };
  }
  
  // converts server objects to flutter models
  factory StrokeModel.fromServerObject(Map<String, dynamic> jsonStencil) {
    return StrokeModel(
      pointList: (jsonStencil['pointList'] as List<dynamic>).map((point) { 
        return <double>[point[0].toDouble(), point[1].toDouble()]; 
      }).toList(),
      color: jsonStencil['color'] as int,
      brushSize: (jsonStencil['brushSize'] as num).toDouble(),
    );
  }

  StrokeEntity toEntity() {
    return StrokeEntity(
      pointList: pointList.map((point) { 
        return Offset(point[0], point[1]); 
      }).toList(),
      color: Color(color),
      brushSize: brushSize,
    );
  }

  factory StrokeModel.fromEntity(StrokeEntity entity) {
    return StrokeModel(
      pointList: entity.pointList.map((point) {
        return [point.dx, point.dy];
      }).toList(),
      color: entity.color.toARGB32(),
      brushSize: entity.brushSize,
    );
  }
}