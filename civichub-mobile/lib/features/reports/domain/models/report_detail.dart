import 'package:equatable/equatable.dart';

import 'report_status.dart';

class CitizenReportDetail extends Equatable {
  const CitizenReportDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    this.latitude,
    this.longitude,
    this.categoryId,
    this.categoryName,
    this.departmentId,
    this.departmentName,
    this.citizenId,
    this.citizenName,
    this.images = const [],
    this.resolution,
    this.rating,
    this.timeline = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final String address;
  final ReportStatus status;
  final double? latitude;
  final double? longitude;
  final int? categoryId;
  final String? categoryName;
  final int? departmentId;
  final String? departmentName;
  final int? citizenId;
  final String? citizenName;
  final List<ReportImage> images;
  final ReportResolution? resolution;
  final ReportRating? rating;
  final List<ReportTimelineEvent> timeline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    address,
    status,
    latitude,
    longitude,
    categoryId,
    categoryName,
    departmentId,
    departmentName,
    citizenId,
    citizenName,
    images,
    resolution,
    rating,
    timeline,
    createdAt,
    updatedAt,
  ];
}

class ReportImage extends Equatable {
  const ReportImage({this.id, required this.url, required this.displayOrder});

  final int? id;
  final String url;
  final int displayOrder;

  @override
  List<Object?> get props => [id, url, displayOrder];
}

class ReportResolution extends Equatable {
  const ReportResolution({
    this.id,
    required this.summary,
    this.workPerformed,
    this.publicNote,
    this.resolvedByName,
    this.resolvedAt,
    this.citizenConfirmedAt,
    this.images = const [],
  });

  final int? id;
  final String summary;
  final String? workPerformed;
  final String? publicNote;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final DateTime? citizenConfirmedAt;
  final List<ReportImage> images;

  bool get isConfirmed => citizenConfirmedAt != null;

  @override
  List<Object?> get props => [
    id,
    summary,
    workPerformed,
    publicNote,
    resolvedByName,
    resolvedAt,
    citizenConfirmedAt,
    images,
  ];
}

class ReportRating extends Equatable {
  const ReportRating({
    this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, rating, comment, createdAt, updatedAt];
}

class ReportTimelineEvent extends Equatable {
  const ReportTimelineEvent({
    this.id,
    required this.type,
    required this.title,
    this.description,
    this.actorRole,
    this.actorName,
    this.createdAt,
  });

  final int? id;
  final String type;
  final String title;
  final String? description;
  final String? actorRole;
  final String? actorName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    description,
    actorRole,
    actorName,
    createdAt,
  ];
}
