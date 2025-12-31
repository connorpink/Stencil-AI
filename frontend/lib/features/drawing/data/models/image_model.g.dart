// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageModelAdapter extends TypeAdapter<ImageModel> {
  @override
  final int typeId = 2;

  @override
  ImageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageModel(
      path: fields[0] as String,
      url: fields[1] as String,
      size: fields[2] as int?,
      orig_name: fields[3] as String?,
      mime_type: fields[4] as String?,
      is_stream: fields[5] as bool,
      meta: fields[6] as dynamic,
      content: fields[7] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.orig_name)
      ..writeByte(4)
      ..write(obj.mime_type)
      ..writeByte(5)
      ..write(obj.is_stream)
      ..writeByte(6)
      ..write(obj.meta)
      ..writeByte(7)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
