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
      imageList: (fields[1] as List).cast<ImageModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, StencilModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.prompt)
      ..writeByte(1)
      ..write(obj.imageList);
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
