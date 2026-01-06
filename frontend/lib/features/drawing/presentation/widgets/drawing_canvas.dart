import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';

class DrawingCanvas extends StatefulWidget {

  final List<StrokeEntity> strokeList;
  final Color currentStrokeColor;
  final double currentStrokeBrushSize;
  final void Function(StrokeEntity) handleNewStroke;

  const DrawingCanvas({
    super.key,
    required this.strokeList,
    required this.currentStrokeColor,
    required this.currentStrokeBrushSize,
    required this.handleNewStroke,
  });

  @override
  State<DrawingCanvas> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawingCanvas> {

  List<Offset> _currentStrokePointList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleEndStroke() {
    if (_currentStrokePointList.isEmpty) { return; }

    final StrokeEntity newStroke = StrokeEntity(
      pointList: List.from(_currentStrokePointList), // make a copy so the list can be reset without the parent loosing access to the strokes
      color: widget.currentStrokeColor, 
      brushSize: widget.currentStrokeBrushSize
    );
    widget.handleNewStroke(newStroke);
    setState(() { _currentStrokePointList = []; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) { setState(() { _currentStrokePointList = [details.localPosition]; }); },
      onPanUpdate: (details) { setState(() { _currentStrokePointList.add(details.localPosition); }); },
      onPanEnd: (details) { _handleEndStroke(); },

      child: Stack (
        children: [
          // Static layer - only repaints when strokeList changes
          RepaintBoundary( 
            child: CustomPaint(
              size: Size.infinite,
              painter: CanvasPainter( strokeList: widget.strokeList ),
            ), 
          ),
          // dynamic layer - repaints every time the current line is adjusted
          RepaintBoundary(
            child: CustomPaint( 
              size: Size.infinite,
              painter: StrokePainter ( stroke: StrokeEntity(pointList: _currentStrokePointList, color: widget.currentStrokeColor, brushSize: widget.currentStrokeBrushSize) ), 
            ),
          ),
        ]
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<StrokeEntity> strokeList;
  late final int strokeCount = strokeList.length;

  CanvasPainter({
    super.repaint,
    required this.strokeList,
  });

  @override
  void paint (Canvas canvas, Size size) {
    for (final stroke in strokeList) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.brushSize
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.pointList.length - 1; i++) {
        canvas.drawLine(stroke.pointList[i], stroke.pointList[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldCanvas) {
    return oldCanvas.strokeCount != strokeCount;
  }
}

class StrokePainter extends CustomPainter {
  final StrokeEntity stroke;

  StrokePainter({
    super.repaint,
    required this.stroke,
  });

  @override
  void paint (Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.brushSize
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stroke.pointList.length - 1; i++) {
      canvas.drawLine(stroke.pointList[i], stroke.pointList[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter oldCanvas) { 
    return true;
  }
}