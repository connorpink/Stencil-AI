// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrokeModelAdapter extends TypeAdapter<StrokeModel> {
  @override
  final int typeId = 3;

  @override
  StrokeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrokeModel(
      pointList: (fields[0] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList(),
      color: fields[1] as int,
      brushSize: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StrokeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.pointList)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.brushSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
