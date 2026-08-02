import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';

class ReportDetailResponse {
  const ReportDetailResponse({
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
  final List<ReportImageResponse> images;
  final ReportResolutionResponse? resolution;
  final ReportRatingResponse? rating;
  final List<ReportTimelineEventResponse> timeline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReportDetailResponse.fromJson(Map<String, dynamic> json) {
    return ReportDetailResponse(
      id: _requiredInt(json['id']),
      title: _stringOrEmpty(json['title']),
      description: _stringOrEmpty(json['description']),
      address: _stringOrEmpty(json['address']),
      status: ReportStatus.fromApiValue(json['status']),
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      categoryId: _nullableInt(json['categoryId']),
      categoryName: _nullableString(json['categoryName']),
      departmentId: _nullableInt(json['departmentId']),
      departmentName: _nullableString(json['departmentName']),
      citizenId: _nullableInt(json['citizenId']),
      citizenName: _nullableString(json['citizenName']),
      images: _imagesFromJson(json['images']),
      resolution: _resolutionFromJson(json['resolution']),
      rating: _ratingFromJson(json['rating']),
      timeline: _timelineFromJson(json['timeline']),
      createdAt: _nullableDateTime(json['createdAt']),
      updatedAt: _nullableDateTime(json['updatedAt']),
    );
  }

  CitizenReportDetail toDomain() {
    return CitizenReportDetail(
      id: id,
      title: title,
      description: description,
      address: address,
      status: status,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      citizenId: citizenId,
      citizenName: citizenName,
      images: images.map((image) => image.toDomain()).toList(),
      resolution: resolution?.toDomain(),
      rating: rating?.toDomain(),
      timeline: timeline.map((event) => event.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ReportResolutionResponse? _resolutionFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid resolution field');
    }
    return ReportResolutionResponse.fromJson(value);
  }

  static ReportRatingResponse? _ratingFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid rating field');
    }
    return ReportRatingResponse.fromJson(value);
  }

  static List<ReportTimelineEventResponse> _timelineFromJson(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException('Invalid timeline field');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid timeline item');
      }
      return ReportTimelineEventResponse.fromJson(item);
    }).toList();
  }

  static List<ReportImageResponse> _imagesFromJson(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException('Invalid images field');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid image item');
      }
      return ReportImageResponse.fromJson(item);
    }).toList();
  }

  static int _requiredInt(Object? value) {
    final parsed = _nullableInt(value);
    if (parsed == null) {
      throw const FormatException('Missing report id');
    }
    return parsed;
  }

  static int? _nullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _nullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static String _stringOrEmpty(Object? value) {
    return value is String ? value : '';
  }

  static String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class ReportImageResponse {
  const ReportImageResponse({
    this.id,
    required this.url,
    required this.displayOrder,
  });

  final int? id;
  final String url;
  final int displayOrder;

  factory ReportImageResponse.fromJson(Map<String, dynamic> json) {
    return ReportImageResponse(
      id: ReportDetailResponse._nullableInt(json['id']),
      url: ReportDetailResponse._stringOrEmpty(json['url']),
      displayOrder:
          ReportDetailResponse._nullableInt(json['displayOrder']) ?? 0,
    );
  }

  ReportImage toDomain() {
    return ReportImage(id: id, url: url, displayOrder: displayOrder);
  }
}

class ReportResolutionResponse {
  const ReportResolutionResponse({
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
  final List<ReportImageResponse> images;

  factory ReportResolutionResponse.fromJson(Map<String, dynamic> json) {
    return ReportResolutionResponse(
      id: ReportDetailResponse._nullableInt(json['id']),
      summary: ReportDetailResponse._stringOrEmpty(json['summary']),
      workPerformed: ReportDetailResponse._nullableString(
        json['workPerformed'],
      ),
      publicNote: ReportDetailResponse._nullableString(json['publicNote']),
      resolvedByName: ReportDetailResponse._nullableString(
        json['resolvedByName'],
      ),
      resolvedAt: ReportDetailResponse._nullableDateTime(json['resolvedAt']),
      citizenConfirmedAt: ReportDetailResponse._nullableDateTime(
        json['citizenConfirmedAt'],
      ),
      images: ReportDetailResponse._imagesFromJson(json['images']),
    );
  }

  ReportResolution toDomain() {
    return ReportResolution(
      id: id,
      summary: summary,
      workPerformed: workPerformed,
      publicNote: publicNote,
      resolvedByName: resolvedByName,
      resolvedAt: resolvedAt,
      citizenConfirmedAt: citizenConfirmedAt,
      images: images.map((image) => image.toDomain()).toList(),
    );
  }
}

class ReportRatingResponse {
  const ReportRatingResponse({
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

  factory ReportRatingResponse.fromJson(Map<String, dynamic> json) {
    return ReportRatingResponse(
      id: ReportDetailResponse._nullableInt(json['id']),
      rating: ReportDetailResponse._nullableInt(json['rating']) ?? 0,
      comment: ReportDetailResponse._nullableString(json['comment']),
      createdAt: ReportDetailResponse._nullableDateTime(json['createdAt']),
      updatedAt: ReportDetailResponse._nullableDateTime(json['updatedAt']),
    );
  }

  ReportRating toDomain() {
    return ReportRating(
      id: id,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ReportTimelineEventResponse {
  const ReportTimelineEventResponse({
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

  factory ReportTimelineEventResponse.fromJson(Map<String, dynamic> json) {
    return ReportTimelineEventResponse(
      id: ReportDetailResponse._nullableInt(json['id']),
      type: ReportDetailResponse._stringOrEmpty(json['type']),
      title: ReportDetailResponse._stringOrEmpty(json['title']),
      description: ReportDetailResponse._nullableString(json['description']),
      actorRole: ReportDetailResponse._nullableString(json['actorRole']),
      actorName: ReportDetailResponse._nullableString(json['actorName']),
      createdAt: ReportDetailResponse._nullableDateTime(json['createdAt']),
    );
  }

  ReportTimelineEvent toDomain() {
    return ReportTimelineEvent(
      id: id,
      type: type,
      title: title,
      description: description,
      actorRole: actorRole,
      actorName: actorName,
      createdAt: createdAt,
    );
  }
}
