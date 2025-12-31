import 'dart:ui';

class OffsetEntity {
  final double dx;
  final double dy;

  OffsetEntity({
    required this.dx,
    required this.dy,
  });

  Offset toOffset() => Offset(dx, dy);

  factory OffsetEntity.fromOffset(Offset offset) {
    return OffsetEntity(
      dx: offset.dx, 
      dy: offset.dy
    );
  }
}