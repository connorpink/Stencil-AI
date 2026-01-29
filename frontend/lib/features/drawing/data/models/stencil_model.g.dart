// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stencil_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StencilModelAdapter extends TypeAdapter<StencilModel> {
  @override
  final int typeId = 1;

  @override
  StencilModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StencilModel(
      prompt: fields[0] as String,
      preferredImageIndex: fields[1] as int,
      imageList: (fields[2] as List).cast<ImageModel>(),
      position: (fields[3] as List?)?.cast<double>(),
      rotation: fields[4] as double?,
      scale: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StencilModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.prompt)
      ..writeByte(1)
      ..write(obj.preferredImageIndex)
      ..writeByte(2)
      ..write(obj.imageList)
      ..writeByte(3)
      ..write(obj.position)
      ..writeByte(4)
      ..write(obj.rotation)
      ..writeByte(5)
      ..write(obj.scale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StencilModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
