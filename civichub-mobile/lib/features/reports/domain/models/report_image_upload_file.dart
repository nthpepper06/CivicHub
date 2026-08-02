import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ReportImageUploadFile extends Equatable {
  const ReportImageUploadFile({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;

  int get size => bytes.lengthInBytes;

  @override
  List<Object?> get props => [fileName, contentType, bytes];
}
