import '../../domain/models/create_report_request.dart';

class CreateReportRequestDto {
  const CreateReportRequestDto(this.request);

  final CreateReportRequest request;

  Map<String, dynamic> toJson() {
    final imageUrls = request.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return {
      'title': request.title.trim(),
      'description': request.description.trim(),
      'address': request.address.trim(),
      'latitude': request.latitude,
      'longitude': request.longitude,
      'categoryId': request.categoryId,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
    };
  }
}
