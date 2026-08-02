import '../../domain/models/uploaded_report_image.dart';

class ReportImageUploadResponse {
  const ReportImageUploadResponse({
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  final String url;
  final String fileName;
  final String contentType;
  final int size;

  factory ReportImageUploadResponse.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final fileName = json['fileName'];
    final contentType = json['contentType'];
    final size = json['size'];
    if (url is! String ||
        fileName is! String ||
        contentType is! String ||
        size is! num) {
      throw const FormatException('Invalid report image upload response');
    }
    return ReportImageUploadResponse(
      url: url,
      fileName: fileName,
      contentType: contentType,
      size: size.toInt(),
    );
  }

  UploadedReportImage toDomain() {
    return UploadedReportImage(
      url: url,
      fileName: fileName,
      contentType: contentType,
      size: size,
    );
  }
}
