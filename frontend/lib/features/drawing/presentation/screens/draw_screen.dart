import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter/material.dart';

import 'package:flutter_frontend/features/drawing/domain/entities/stroke_entity.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen_widgets/drawing_canvas.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen_widgets/select_color_button.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen_widgets/stencil_canvas.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen_widgets/stencil_select_panel.dart';

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
  late ArtworkEntity _artwork;

  bool _editStencilMode = false;
  bool _stencilPanelOpen = false;

  // stroke list variables
  // ignore: prefer_final_fields
  List<StrokeEntity> _redoStrokeList = [];
  List<StrokeEntity> _activeStrokeList = []; 

  Color _currentStrokeColor = Colors.black;
  double _currentStrokeBrushSize = 4.0;

  @override
  void initState() {
    super.initState();
    _artwork = widget.artwork;
    _activeStrokeList = _artwork.strokeList;
  }

  void _togglePanel() {
    setState(() {
      _stencilPanelOpen = !_stencilPanelOpen;
    });
  }

  void _setPanelOpen(bool setting) {
    setState(() {
      _stencilPanelOpen = setting;
    });
    _stencilPanelOpen = setting;
  }

  Future<void> _saveDrawing(String title) async {
    _artwork.strokeList = _activeStrokeList;
    widget.artworkRepository.saveArtwork(_artwork);

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

  void _handleNewStroke(StrokeEntity newStroke) {
    setState(() { _activeStrokeList.add(newStroke); });
  }

  void _handleNewColor(Color newColor) {
    setState(() { _currentStrokeColor = newColor; });
  }

  void _handleStencilUpdate(int index, StencilEntity stencil) {
    _artwork.stencilList[index] = stencil;
  }

  void _handleStencilRemoveFromCanvas(int index) {
    _artwork.stencilList[index] = _artwork.stencilList[index].copyWith(
      position: null,
      rotation: null,
      scale: null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    final stencilCanvas = RepaintBoundary(
      child: StencilCanvas( 
        stencilList: _artwork.stencilList,
        onStencilUpdate: _handleStencilUpdate,
        onStencilRemove: _handleStencilRemoveFromCanvas,
      ),
    );

    final drawingCanvas = RepaintBoundary(
      child: DrawingCanvas(
        strokeList: _activeStrokeList,
        currentStrokeColor: _currentStrokeColor,
        currentStrokeBrushSize: _currentStrokeBrushSize, 
        handleNewStroke: _handleNewStroke,
      ),
    );

    return Stack (
      children: [
        Scaffold(

          appBar: AppBar(
            title: Text(_artwork.title),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Stencil Mode"),
                  Switch(
                    value: _editStencilMode,
                    onChanged: (bool value) {
                      setState(() {
                        _editStencilMode = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),

          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [ 

                    stencilCanvas,
                    if (!_editStencilMode) ...[
                      drawingCanvas,
                    ],

                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_editStencilMode) ...[
                            FloatingActionButton(
                              heroTag: 'Image Panel',
                              onPressed: _togglePanel,
                              child: const Icon(Icons.image)
                            ),
                          ],
                          FloatingActionButton(
                            heroTag: 'Save',
                            onPressed: _showSaveDialog,
                            child: const Icon(Icons.save)
                          ),
                        ]
                      ),
                    ),

                  ]
                ),
              ),

              // ------------ SETTINGS PANEL START ------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _activeStrokeList.isNotEmpty ? () {
                        setState(() { _redoStrokeList.add(_activeStrokeList.removeLast()); });
                      } : null,
                      icon: const Icon(Icons.undo)
                    ),

                    IconButton(
                      onPressed: _redoStrokeList.isNotEmpty ? () {
                        setState(() { _activeStrokeList.add(_redoStrokeList.removeLast()); });
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
                        SelectColorButton(
                          color: Colors.black,
                          currentlySelected: (Colors.black == _currentStrokeColor),
                          handleColorSelected: _handleNewColor
                        ),
                        SelectColorButton(
                          color: Colors.red,
                          currentlySelected: (Colors.red == _currentStrokeColor),
                          handleColorSelected: _handleNewColor
                        ),
                        SelectColorButton(
                          color: Colors.blue,
                          currentlySelected: (Colors.blue == _currentStrokeColor),
                          handleColorSelected: _handleNewColor
                        ),
                        SelectColorButton(
                          color: Colors.green,
                          currentlySelected: (Colors.green == _currentStrokeColor),
                          handleColorSelected: _handleNewColor
                        ),
                      ],
                    )
                  ],
                )
              )
              // ------------ SETTINGS PANEL END ------------
            ]
          ),

        ),

        // panel off to the side of the screen
        StencilSelectPanel(
          stencilList: _artwork.stencilList,
          isPanelOpen: _stencilPanelOpen,
          setPanelOpen: _setPanelOpen,
        ),
      ]
    );
  }
}