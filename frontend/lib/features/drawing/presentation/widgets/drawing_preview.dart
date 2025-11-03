import 'dart:typed_data';
import 'dart:ui';
import '../../data/models/stroke.dart';
import 'package:flutter/material.dart';

Future<Uint8List> generateThumbnail(List<Stroke> strokes, double width, double height) async {

  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  // get the size of the drawing by recording the location of the fairest out strokes
  for (final stroke in strokes) {
    for (final point in stroke.offsetPoints) {
      if (point != Offset.zero) {
        minX = minX < point.dx ? minX : point.dx;
        minY = minY < point.dy ? minY : point.dy;
        maxX = maxX > point.dx ? maxX : point.dx;
        maxY = maxY > point.dy ? maxY : point.dy;
      }
    }
  }
  final drawingWidth = maxX - minX;
  final drawingHeight = maxY - minY;

  // Calculate scale to fit within thumbnail while maintaining aspect ratio
  final scale = (width / drawingWidth < height / drawingHeight) ? width / drawingWidth : height / drawingHeight;

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
  final paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  canvas.drawRect(Rect.fromLTWH(0, 0, width, height,), paint);

  // Center the drawing in the thumbnail
  final offsetX = (width - drawingWidth * scale) / 2 - minX * scale;
  final offsetY = (height - drawingHeight * scale) / 2 - minY * scale;
  
  // create the drawing for the thumbnail
  for (final stroke in strokes) {
    final strokePaint = Paint()
      ..color = Color(stroke.color)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke.brushSize * scale;
    final points = stroke.offsetPoints;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        final p1 = Offset(points[i].dx * scale + offsetX, points[i].dy * scale + offsetY);
        final p2 = Offset(points[i + 1].dx * scale + offsetX, points[i + 1].dy * scale + offsetY);
        canvas.drawLine(p1, p2, strokePaint);
      }
    }
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}