import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/stencil_entity.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen_widgets/interactive_stencil.dart';

class StencilCanvas extends StatelessWidget {
  final List<StencilEntity> stencilList;
  final Function(int index, StencilEntity updated) onStencilUpdate;
  final Function(int index) onStencilRemove;

  const StencilCanvas({
    super.key,
    required this.stencilList,
    required this.onStencilUpdate,
    required this.onStencilRemove,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final updatedStencil = stencilList[details.data].copyWith(
          position: details.offset,
          rotation: 0.0,
          scale: 1.0,
        );
        onStencilUpdate(details.data, updatedStencil);
      },
      builder: (context, candidateData, rejectedData) { 
        return SizedBox.expand(
          child: Stack (
            children: stencilList
              .asMap()
              .entries
              .where((entry) => entry.value.position != null)
              .map((entry) {
                final index = entry.key;
                final stencil = entry.value;
                final image = stencil.imageList[stencil.preferredImageIndex];
          
                return InteractiveStencil(
                  key: ValueKey(index),
                  position: stencil.position!,
                  rotation: stencil.rotation!,
                  scale: stencil.scale!,
                  image: image.content,
                  onUpdate: (position, rotation, scale) {
                    final updatedStencil = stencil.copyWith(
                      position: position,
                      rotation: rotation,
                      scale: scale,
                    );
                    onStencilUpdate(index, updatedStencil);
                  },
                  onRemove: () => onStencilRemove(index),
                );
              })
              .toList(),
          ),
        );
      }
    );
  }
}