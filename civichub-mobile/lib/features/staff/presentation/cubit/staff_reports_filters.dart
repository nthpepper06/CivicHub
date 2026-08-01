import '../../../reports/domain/models/report_status.dart';

class StaffReportsFilters {
  const StaffReportsFilters({
    this.search = '',
    this.status,
    this.categoryId,
    this.citizenId,
    this.createdFrom,
    this.createdTo,
  });

  final String search;
  final ReportStatus? status;
  final int? categoryId;
  final int? citizenId;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  bool get hasActive =>
      search.isNotEmpty ||
      status != null ||
      categoryId != null ||
      citizenId != null ||
      createdFrom != null ||
      createdTo != null;

  StaffReportsFilters copyWith({
    String? search,
    Object? status = _unchanged,
    Object? categoryId = _unchanged,
    Object? citizenId = _unchanged,
    Object? createdFrom = _unchanged,
    Object? createdTo = _unchanged,
  }) {
    return StaffReportsFilters(
      search: search ?? this.search,
      status: status == _unchanged ? this.status : status as ReportStatus?,
      categoryId: categoryId == _unchanged
          ? this.categoryId
          : categoryId as int?,
      citizenId: citizenId == _unchanged ? this.citizenId : citizenId as int?,
      createdFrom: createdFrom == _unchanged
          ? this.createdFrom
          : createdFrom as DateTime?,
      createdTo: createdTo == _unchanged
          ? this.createdTo
          : createdTo as DateTime?,
    );
  }
}

const _unchanged = Object();
