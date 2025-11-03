import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/drawing_preview.dart';
import 'package:hive/hive.dart';
import '../../data/models/stroke.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStrokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;
  late Box<Map<dynamic, dynamic>> _drawingBox;
  String? _drawingName;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHive();
    });
    super.initState();
  }

  Future<void> _initializeHive() async {
    _drawingBox = Hive.box<Map<dynamic, dynamic>>('drawings');
    final name = ModalRoute.of(context)?.settings.arguments as String?;
    if(name != null) {
      final rawData = _drawingBox.get(name);
      setState(() {
        _drawingName = name;
        _strokes = (rawData?['strokes'] as List<dynamic>?)?.cast<Stroke>() ?? [];
      });
    }
  }

  Future<void> _saveDrawing(String name) async {

    final Uint8List thumbnail = await generateThumbnail(_strokes, 200, 200);

    await _drawingBox.put(name, {
      'strokes': _strokes,
      'thumbnail': thumbnail
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Drawing $name saved!'))
    );
  }

  // Popup for when the user tries to save there drawing
  void _showSaveDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Drawing"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter drawing name'),
          ),
          actions: [
            TextButton(onPressed: (){
              Navigator.of(context).pop();
            }, 
            child: Text('Cancel')
            ),
            TextButton(onPressed: (){
              final name = _controller.text.trim();
              if(name.isNotEmpty){
                setState(() {
                  _drawingName = name;
                });
                _saveDrawing(name);
                Navigator.of(context).pop();
              }
            }, 
            child: Text('Save')
            )
          ],
        );
      }
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_drawingName ?? "New creation")
      ),

      body: Column(
        children: [
          Expanded(
            child: Scaffold(
              body: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentPoints = [details.localPosition];
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentPoints.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _strokes.add(
                      Stroke.fromOffset(
                        offsets: List<Offset>.of(_currentPoints), 
                        color: _selectedColor,
                        brushSize: _brushSize
                      ),
                    );
                    _currentPoints = [];
                    _redoStrokes = [];
                  });
                },
                child: CustomPaint(
                  painter: DrawPainter(
                    strokes: _strokes,
                    currentPoints: _currentPoints,
                    currentColor: _selectedColor,
                    currentBrushSize: _brushSize
                  ),
                  size: Size.infinite
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: _showSaveDialog,
                child: const Icon(Icons.save)
              ),
            ),
        ),
          _buildToolBar(),
        ]
      ),
    );
  }

  Widget _buildToolBar(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _strokes.isNotEmpty ? () {
              setState(() {
                _redoStrokes.add(_strokes.removeLast());
              });
            } : null,
            icon: const Icon(Icons.undo)
          ),
          IconButton(
            onPressed: _redoStrokes.isNotEmpty ? () {
              setState(() {
                _strokes.add(_redoStrokes.removeLast());
              });
            } : null,
            icon: const Icon(Icons.redo)
          ),

          DropdownButton(
            value: _brushSize,
            items: [
              DropdownMenuItem(
                value: 2.0,
                child: Text('small')
              ),
              DropdownMenuItem(
                value: 4.0,
                child: Text('medium')
              ),
              DropdownMenuItem(
                value: 8.0,
                child: Text('large')
              )
            ],
            onChanged: (value) {
              setState(() {
                _brushSize = value!;
              });
            }
          ),

          Row(
            children: [
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.green),
            ],
          )
        ],
      )
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: (){
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.grey : Colors.transparent
          )
        )
      )
    );
  }
}

class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentBrushSize;

  DrawPainter({super.repaint, required this.strokes, required this.currentPoints, required this.currentColor, required this.currentBrushSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.brushSize;

      final points = stroke.offsetPoints;
      for(int i=0; i < stroke.points.length-1; i++) {
        if(points[i] != Offset.zero && points[i+1] != Offset.zero){
          canvas.drawLine(points[i], points[i+1], paint);
        }
      }
    }

    final paint = Paint()
      ..color = currentColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = currentBrushSize;
    
    for(int i=0; i < currentPoints.length-1; i++) {
      if(currentPoints[i] != Offset.zero && currentPoints[i+1] != Offset.zero){
        canvas.drawLine(currentPoints[i], currentPoints[i+1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}