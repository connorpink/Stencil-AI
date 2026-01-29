import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';

class StencilSelectPanel extends StatelessWidget {
  final bool isPanelOpen;
  final List<StencilEntity> stencilList;
  static const double panelWidth = 300.0;
  final Function(bool setting) setPanelOpen;

  const StencilSelectPanel({
    super.key,
    required this.stencilList,
    required this.isPanelOpen,
    required this.setPanelOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(

      // animation settings for the panel
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      left: isPanelOpen ? 0 : - panelWidth,
      width: panelWidth,
      child: Container( 
        decoration: BoxDecoration( 
          color: Theme.of(context).colorScheme.secondary,
          boxShadow: [
            BoxShadow (
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
        ),

        // panel content
        child: Padding (
          padding: EdgeInsets.all(16.0),
          child: Builder(
            builder: (context) {
              final List<({int realIndex, StencilEntity stencil})> filteredList = stencilList
                .asMap()
                .entries
                .map((entry) {
                  if (entry.value.position == null) { return (realIndex: entry.key, stencil: entry.value); }
                  else { return null; }
                })
                .whereType<({int realIndex, StencilEntity stencil})>() // remove null values
                .toList();
              return ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final StencilEntity currentStencil = filteredList[index].stencil;
                  final Uint8List imageContent = currentStencil.imageList[currentStencil.preferredImageIndex].content;
                  return Padding(
                    padding: (index != 0) ? const EdgeInsets.only(top:16.0) : const EdgeInsets.only(top:0.0),
                    child: Draggable<int>(
                      data: filteredList[index].realIndex, // the widget this object is being dragged to should have the same stencilList and will know how to find the correct object with the realIndex
                      onDragStarted: () => setPanelOpen(false),
                      onDragEnd: (details) => setPanelOpen(true),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: ImageSquare(imageContent: imageContent, squareSize: (panelWidth - 32)),
                      ),
                      feedback: ImageSquare(imageContent: imageContent, squareSize: (panelWidth - 32)),
                      child: ImageSquare(imageContent: imageContent, squareSize: (panelWidth - 32)),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ),
    );
  }
}

class ImageSquare extends StatelessWidget {
  final Uint8List? imageContent;
  final double squareSize;

  const ImageSquare({
    super.key,
    required this.imageContent,
    required this.squareSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: imageContent != null
          ? Image.memory(
              imageContent!,
              width: squareSize,
              height: squareSize,
              fit: BoxFit.cover,
            )
          : Text("image failed to load"),
    );
  }
}