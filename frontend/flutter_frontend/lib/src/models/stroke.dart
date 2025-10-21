import 'dart:ui';
import 'package:hive/hive.dart';
import './offset.dart';

part 'stroke.g.dart';

@HiveType(typeId: 1)
class Stroke extends HiveObject{
  @HiveField(0)
  final List<OffsetCustom> points;

  @HiveField(1)
  final int color;

  @HiveField(2)
  final double brushSize;

  Stroke({
    required this.points,
    required this.color,
    required this.brushSize,
  });

  List<Offset> get offsetPoints => points.map((e) => e.toOffset()).toList();

  factory Stroke.fromOffset({
    required List<Offset> offsets,
    required Color color,
    required double brushSize
  }) {
    return Stroke(
      points: offsets.map((e) => OffsetCustom.fromOffset(e)).toList(),
      color: color.toARGB32(),
      brushSize: brushSize
    );
  }
}