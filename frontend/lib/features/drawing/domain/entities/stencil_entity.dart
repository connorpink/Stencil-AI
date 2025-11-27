import 'dart:typed_data';

class StencilEntity {
  final String name;
  final Uint8List imageData;

  StencilEntity({
    required this.name,
    required this.imageData,
  });
}