// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtworkModelAdapter extends TypeAdapter<ArtworkModel> {
  @override
  final int typeId = 0;

  @override
  ArtworkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtworkModel(
      id: fields[0] as String,
      serverId: fields[1] as String?,
      title: fields[2] as String,
      description: fields[3] as String,
      stencilList: (fields[4] as List).cast<StencilModel>(),
      strokeList: (fields[5] as List).cast<StrokeModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ArtworkModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.stencilList)
      ..writeByte(5)
      ..write(obj.strokeList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtworkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
