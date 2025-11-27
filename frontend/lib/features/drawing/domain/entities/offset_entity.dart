import 'dart:ui';

class OffsetEntity {
  final double dx;
  final double dy;

  OffsetEntity(
    this.dx,
    this.dy,
  );

  Offset toOffset() => Offset(dx, dy);

  factory OffsetEntity.fromOffset(Offset offset) {
    return OffsetEntity(offset.dx, offset.dy);
  }
}