import 'dart:typed_data';

class ImageEntity {
  final String path;
  final String url;
  final int? size;
  final String? orig_name;
  final String? mime_type;
  final bool is_stream;
  final dynamic meta;
  final Uint8List? content;

  ImageEntity({
    required this.path,
    required this.url,
    this.size,
    this.orig_name,
    this.mime_type,
    required this.is_stream,
    this.meta,
    this.content,
  });
}