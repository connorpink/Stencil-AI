import 'package:flutter_frontend/features/drawing/domain/entities/offset_entity.dart';
import 'package:hive/hive.dart';

part 'offset_model.g.dart';

@HiveType(typeId: 3)
class OffsetModel extends HiveObject {
  @HiveField(0)
  final double dx;

  @HiveField(1)
  final double dy;

  OffsetModel(
    this.dx, 
    this.dy
  );

  OffsetEntity toEntity() => OffsetEntity(dx, dy);

  factory OffsetModel.fromEntity(OffsetEntity entity){
    return OffsetModel(entity.dx, entity.dy);
  }
}