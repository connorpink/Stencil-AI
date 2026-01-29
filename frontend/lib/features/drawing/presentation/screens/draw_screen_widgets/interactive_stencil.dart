import 'dart:typed_data';
import 'package:flutter/material.dart';

class InteractiveStencil extends StatefulWidget {
  final Uint8List image;
  final Offset position;
  final double rotation;
  final double scale;
  final void Function(Offset position, double rotation, double scale) onUpdate;
  final void Function() onRemove;

  const InteractiveStencil({
    super.key,
    required this.image,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<InteractiveStencil> createState() => _InteractiveStencilState();
}

class _InteractiveStencilState extends State<InteractiveStencil> {
  late Offset _position;
  late double _rotation;
  late double _scale;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _rotation = widget.rotation;
    _scale = widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,

      child: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            _scale *= details.scale;
            _rotation += details.rotation;
          });
        },
        onScaleEnd: (details) {
          widget.onUpdate(_position, _rotation, _scale);
        },

        child: Transform.rotate(
          angle: _rotation,
          child: Transform.scale(
            scale: _scale,
            child: Image.memory(
              widget.image,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          )
        )
      ),
    );
  }
}