import 'package:equatable/equatable.dart';

class UploadedReportImage extends Equatable {
  const UploadedReportImage({
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  final String url;
  final String fileName;
  final String contentType;
  final int size;

  @override
  List<Object?> get props => [url, fileName, contentType, size];
}
