import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter/material.dart';

import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';

class DrawScreen extends StatefulWidget {
  final String? id;

  const DrawScreen({
    super.key,
    this.id,
  });

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {

  late ArtworkEntity _artwork;
  late ArtworkRepositoryInterface _artworkRepository;

  // basic default artwork entity if a valid one doesn't already exist
  ArtworkEntity freshArtworkEntity = ArtworkEntity(
    id: "-1", // -1 is the id for an unsaved artwork
    title: "New Artwork",
    description: "none",
    stencilList: [],
    strokeList: []
  );

  // stroke variables
    // current strokes can be found in artwork.strokeList
  List<StrokeEntity> _redoStrokes = [];
  List<Offset> _currentPoints = [];

  // brush settings
  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;

  @override
  void initState() {
    super.initState();
    _artworkRepository = context.read<ArtworkRepositoryInterface>();
    if (widget.id == null) { _artwork = freshArtworkEntity; }
    else { _artwork = _artworkRepository.fetchArtwork(widget.id!) ?? freshArtworkEntity; }
  }

  Future<void> _saveDrawing(String title) async {
    _artworkRepository.saveArtwork(_artwork);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Drawing $title saved!'))
    );
  }

  // Popup for when the user tries to save there drawing
  void _showSaveDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Drawing"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter drawing name'),
          ),
          actions: [
            TextButton(onPressed: (){
              Navigator.of(context).pop();
            }, 
            child: Text('Cancel')
            ),
            TextButton(onPressed: (){
              final newTitle = controller.text.trim();
              if(newTitle.isNotEmpty){
                setState(() {
                  _artwork.title = newTitle;
                });
                _saveDrawing(newTitle);
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
        title: Text(_artwork.title)
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
                    _artwork.strokeList.add(
                      StrokeEntity.fromOffset(
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
                    strokes: _artwork.strokeList,
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
            onPressed: _artwork.strokeList.isNotEmpty ? () {
              setState(() {
                _redoStrokes.add(_artwork.strokeList.removeLast());
              });
            } : null,
            icon: const Icon(Icons.undo)
          ),
          IconButton(
            onPressed: _redoStrokes.isNotEmpty ? () {
              setState(() {
                _artwork.strokeList.add(_redoStrokes.removeLast());
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
  final List<StrokeEntity> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentBrushSize;

  DrawPainter({super.repaint, required this.strokes, required this.currentPoints, required this.currentColor, required this.currentBrushSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
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