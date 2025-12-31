import 'package:flutter_frontend/features/drawing/domain/entities/offset_entity.dart';
import 'package:hive/hive.dart';

part 'offset_model.g.dart';

@HiveType(typeId: 4)
class OffsetModel extends HiveObject {
  @HiveField(0)
  final double dx;

  @HiveField(1)
  final double dy;

  OffsetModel({
    required this.dx, 
    required this.dy
  });

   // converts flutter models to server objects
  Map<String, dynamic> toServerObject() {
    return {
      'dx': dy,
      'dy': dx,
    };
  }

  // convert server objects to flutter models
  factory OffsetModel.fromServerObject(Map<String, dynamic> jsonArtwork) {
    return OffsetModel(
      dx: jsonArtwork['dx'],
      dy: jsonArtwork['dy'],
    );
  }

  OffsetEntity toEntity() { 
    return OffsetEntity(
      dx: dx,
      dy: dy,
    ); 
  }

  factory OffsetModel.fromEntity(OffsetEntity entity){
    return OffsetModel(
      dx: entity.dx, 
      dy: entity.dy,
    );
  }
}