import 'package:equatable/equatable.dart';

class CreateReportRequest extends Equatable {
  const CreateReportRequest({
    required this.title,
    required this.description,
    required this.address,
    required this.categoryId,
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
  });

  final String title;
  final String description;
  final String address;
  final int categoryId;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;

  @override
  List<Object?> get props => [
    title,
    description,
    address,
    categoryId,
    latitude,
    longitude,
    imageUrls,
  ];
}
