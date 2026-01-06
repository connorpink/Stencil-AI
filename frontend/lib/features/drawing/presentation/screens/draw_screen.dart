import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter/material.dart';

import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/drawing_canvas.dart';

class DrawScreen extends StatefulWidget {
  final ArtworkEntity artwork;
  final ArtworkRepositoryInterface artworkRepository;

  const DrawScreen({
    super.key,
    required this.artwork,
    required this.artworkRepository,
  });

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {

  // stroke variables
  List<StrokeEntity> _redoStrokeList = [];
  List<StrokeEntity> _activeStrokeList = []; 

  Color _currentStrokeColor = Colors.black;
  double _currentStrokeBrushSize = 4.0;

  @override
  void initState() {
    super.initState();
    _activeStrokeList = widget.artwork.strokeList;
  }

  Future<void> _saveDrawing(String title) async {
    widget.artwork.strokeList = _activeStrokeList;
    widget.artworkRepository.saveArtwork(widget.artwork);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Drawing $title saved!'))
    );
  }

  // Popup for when the user tries to save the drawing
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
            TextButton(
              onPressed: (){ 
                Navigator.of(context).pop();
              },
              child: Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if(newTitle.isNotEmpty){
                  setState(() {
                    widget.artwork.title = newTitle;
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

  void _handleNewStroke(StrokeEntity newStroke) {
    setState(() { _activeStrokeList.add(newStroke); });
  }

  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artwork.title)
      ),
      body: Column(
        children: [
          Expanded(
            child: Scaffold(
              body: DrawingCanvas(
                strokeList: _activeStrokeList,
                currentStrokeColor: _currentStrokeColor,
                currentStrokeBrushSize: _currentStrokeBrushSize, 
                handleNewStroke: _handleNewStroke,
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: _showSaveDialog,
                child: const Icon(Icons.save)
              ),
            ),
          ),
          _drawingSettingsBar(),
        ]
      ),
    );
  }



  Widget _drawingSettingsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _activeStrokeList.isNotEmpty ? () {
              setState(() {
                _redoStrokeList.add(_activeStrokeList.removeLast());
              });
            } : null,
            icon: const Icon(Icons.undo)
          ),

          IconButton(
            onPressed: _redoStrokeList.isNotEmpty ? () {
              setState(() {
                _activeStrokeList.add(_redoStrokeList.removeLast());
              });
            } : null,
            icon: const Icon(Icons.redo)
          ),

          DropdownButton(
            value: _currentStrokeBrushSize,
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
                _currentStrokeBrushSize = value!;
              });
            }
          ),

          Row(
            children: [
              _selectColorButton(Colors.black),
              _selectColorButton(Colors.red),
              _selectColorButton(Colors.blue),
              _selectColorButton(Colors.green),
            ],
          )
        ],
      )
    );
  }



  Widget _selectColorButton(Color color) {
    return GestureDetector(
      onTap: (){
        setState(() {
          _currentStrokeColor = color;
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
            color: _currentStrokeColor == color ? Colors.grey : Colors.transparent
          )
        )
      )
    );
  }
}