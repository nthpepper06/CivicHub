import 'package:civichub_mobile/core/storage/auth_token_storage.dart';
import 'package:civichub_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:civichub_mobile/features/auth/data/models/change_password_request.dart';
import 'package:civichub_mobile/features/auth/data/models/login_request.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/data/models/profile_update_request.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_session.dart';
import 'package:civichub_mobile/features/auth/domain/models/citizen_profile.dart';
import 'package:civichub_mobile/features/notifications/domain/models/citizen_notification.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notification_type.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notifications_page.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_category.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_summary.dart';
import 'package:civichub_mobile/features/reports/domain/models/reports_page.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/staff/domain/models/staff_dashboard_summary.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';

class MemoryAuthTokenStorage implements AuthTokenStorage {
  String? _token;

  @override
  Future<void> deleteAccessToken() async {
    _token = null;
  }

  @override
  Future<bool> hasAccessToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> saveAccessToken(String token) async {
    _token = token;
  }
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource({
    this.loginResponse,
    this.currentUserResponse,
    this.loginError,
    this.currentUserError,
    this.updateUserError,
    this.changePasswordError,
    this.loginFuture,
    this.currentUserFuture,
    this.updateUserFuture,
  });

  final LoginResponse? loginResponse;
  CitizenProfile? currentUserResponse;
  Object? loginError;
  Object? currentUserError;
  Object? updateUserError;
  Object? changePasswordError;
  final Future<LoginResponse>? loginFuture;
  final Future<CitizenProfile>? currentUserFuture;
  final Future<CitizenProfile>? updateUserFuture;
  int loginCalls = 0;
  int currentUserCalls = 0;
  int updateUserCalls = 0;
  int changePasswordCalls = 0;
  final profileUpdateRequests = <ProfileUpdateRequest>[];

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    loginCalls += 1;
    if (loginError != null) {
      throw loginError!;
    }
    if (loginFuture != null) {
      return loginFuture!;
    }
    return loginResponse ?? sampleLoginResponse();
  }

  @override
  Future<CitizenProfile> getCurrentUser() async {
    currentUserCalls += 1;
    if (currentUserError != null) {
      throw currentUserError!;
    }
    if (currentUserFuture != null) {
      return currentUserFuture!;
    }
    return currentUserResponse ?? sampleUser();
  }

  @override
  Future<CitizenProfile> updateCurrentUser(ProfileUpdateRequest request) async {
    updateUserCalls += 1;
    profileUpdateRequests.add(request);
    if (updateUserError != null) {
      throw updateUserError!;
    }
    if (updateUserFuture != null) {
      return updateUserFuture!;
    }
    final base = currentUserResponse ?? sampleUser();
    final updated = base.copyWith(
      fullName: request.fullName.trim(),
      phone: request.phone?.trim().isEmpty ?? true
          ? null
          : request.phone?.trim(),
      avatar: request.avatar?.trim().isEmpty ?? true
          ? null
          : request.avatar?.trim(),
    );
    currentUserResponse = updated;
    return updated;
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    changePasswordCalls += 1;
    if (changePasswordError != null) {
      throw changePasswordError!;
    }
  }
}

CitizenProfile sampleUser({UserRole role = UserRole.citizen, int? id = 1}) {
  return CitizenProfile(
    id: id,
    fullName: 'Nguyen Minh Anh',
    email: 'minh.anh@civichub.vn',
    phone: '+84 912 345 678',
    avatar: null,
    role: role,
    status: UserStatus.active,
    isActive: true,
    departmentId: null,
    departmentName: null,
    createdAt: DateTime.parse('2026-07-01T08:00:00'),
    updatedAt: DateTime.parse('2026-07-20T10:15:00'),
  );
}

LoginResponse sampleLoginResponse() {
  return LoginResponse(
    accessToken: 'jwt-token',
    tokenType: 'Bearer',
    expiresIn: 86400,
    user: sampleUser(),
  );
}

AuthSession sampleSession() {
  return sampleLoginResponse().toSession();
}

class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({
    List<ReportsPage<CitizenReportSummary>>? pages,
    List<ReportCategory>? categories,
    CitizenReportDetail? createdReport,
  }) : _pages = List.of(pages ?? [sampleReportsPage()]),
       _categories = categories ?? [sampleCategory()],
       _createdReport = createdReport ?? sampleReportDetail();

  final List<ReportsPage<CitizenReportSummary>> _pages;
  final List<ReportCategory> _categories;
  final CitizenReportDetail _createdReport;
  CitizenReportDetail? detailReport;
  final calls = <ReportRepositoryCall>[];
  final detailCalls = <int>[];
  final createRequests = <CreateReportRequest>[];
  final updateRequests = <({int id, CreateReportRequest request})>[];
  final cancelCalls = <int>[];
  int categoryCalls = 0;
  Object? error;
  Object? categoryError;
  Object? createError;
  Object? detailError;
  Object? updateError;
  Object? cancelError;
  Future<ReportsPage<CitizenReportSummary>>? pendingResponse;
  Future<CitizenReportDetail>? pendingCreateResponse;
  Future<CitizenReportDetail>? pendingDetailResponse;
  Future<CitizenReportDetail>? pendingUpdateResponse;
  Future<CitizenReportDetail>? pendingCancelResponse;

  @override
  Future<List<ReportCategory>> getCategories() async {
    categoryCalls += 1;
    if (categoryError != null) {
      throw categoryError!;
    }
    return _categories;
  }

  @override
  Future<CitizenReportDetail> createReport(CreateReportRequest request) async {
    createRequests.add(request);
    if (createError != null) {
      throw createError!;
    }
    if (pendingCreateResponse != null) {
      return pendingCreateResponse!;
    }
    return _createdReport;
  }

  @override
  Future<CitizenReportDetail> getMyReport(int id) async {
    detailCalls.add(id);
    if (detailError != null) {
      throw detailError!;
    }
    if (pendingDetailResponse != null) {
      return pendingDetailResponse!;
    }
    return detailReport ?? sampleReportDetail(id: id);
  }

  @override
  Future<CitizenReportDetail> updateMyReport(
    int id,
    CreateReportRequest request,
  ) async {
    updateRequests.add((id: id, request: request));
    if (updateError != null) {
      throw updateError!;
    }
    if (pendingUpdateResponse != null) {
      return pendingUpdateResponse!;
    }
    return sampleReportDetail(
      id: id,
      title: request.title.trim(),
      description: request.description.trim(),
      address: request.address.trim(),
    );
  }

  @override
  Future<CitizenReportDetail> cancelMyReport(int id) async {
    cancelCalls.add(id);
    if (cancelError != null) {
      throw cancelError!;
    }
    if (pendingCancelResponse != null) {
      return pendingCancelResponse!;
    }
    detailReport = sampleReportDetail(id: id, status: ReportStatus.cancelled);
    return detailReport!;
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getMyReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    String? sortBy,
    String? direction,
  }) async {
    calls.add(
      ReportRepositoryCall(
        page: page,
        size: size,
        search: search,
        status: status,
        categoryId: categoryId,
        sortBy: sortBy,
        direction: direction,
      ),
    );
    if (error != null) {
      throw error!;
    }
    if (pendingResponse != null) {
      return pendingResponse!;
    }
    if (_pages.isEmpty) {
      return sampleReportsPage(content: const [], page: page, last: true);
    }
    return _pages.removeAt(0);
  }
}

ReportCategory sampleCategory({
  int id = 7,
  String name = 'Roads',
  bool isActive = true,
}) {
  return ReportCategory(
    id: id,
    name: name,
    description: 'Road and sidewalk issues',
    icon: 'road',
    isActive: isActive,
  );
}

class ReportRepositoryCall {
  const ReportRepositoryCall({
    required this.page,
    required this.size,
    this.search,
    this.status,
    this.categoryId,
    this.citizenId,
    this.createdFrom,
    this.createdTo,
    this.sortBy,
    this.direction,
  });

  final int page;
  final int size;
  final String? search;
  final ReportStatus? status;
  final int? categoryId;
  final int? citizenId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final String? sortBy;
  final String? direction;
}

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    List<CitizenNotification>? notifications,
    this.unreadCount = 0,
  }) : _notifications = notifications ?? const [];

  List<CitizenNotification> _notifications;
  int unreadCount;
  int listCalls = 0;
  int countCalls = 0;
  int markCalls = 0;
  Object? error;
  Object? countError;
  Object? markError;

  @override
  Future<NotificationsPage<CitizenNotification>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  }) async {
    listCalls += 1;
    if (error != null) {
      throw error!;
    }
    return NotificationsPage(
      content: _notifications,
      page: 0,
      size: size,
      totalElements: _notifications.length,
      totalPages: 1,
      first: true,
      last: true,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    countCalls += 1;
    if (countError != null) {
      throw countError!;
    }
    return unreadCount;
  }

  @override
  Future<CitizenNotification> markAsRead(int id) async {
    markCalls += 1;
    if (markError != null) {
      throw markError!;
    }
    final updated = _notifications
        .firstWhere((notification) => notification.id == id)
        .copyWith(isRead: true);
    _notifications = _notifications
        .map((notification) => notification.id == id ? updated : notification)
        .toList(growable: false);
    return updated;
  }
}

class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository({
    StaffDashboardSummary? summary,
    List<ReportsPage<CitizenReportSummary>>? pages,
  }) : _summary = summary ?? sampleStaffSummary(),
       _pages = List.of(pages ?? [sampleReportsPage()]);

  final StaffDashboardSummary _summary;
  final List<ReportsPage<CitizenReportSummary>> _pages;
  final assignedCalls = <ReportRepositoryCall>[];
  final detailCalls = <int>[];
  final statusUpdateCalls = <({int id, ReportStatus status})>[];
  int summaryCalls = 0;
  int recentCalls = 0;
  Object? summaryError;
  Object? recentError;
  Object? assignedError;
  Object? detailError;
  Object? updateStatusError;
  ReportsPage<CitizenReportSummary>? recentReportsPage;
  CitizenReportDetail? assignedReportDetail;
  Future<CitizenReportDetail>? pendingUpdateStatusResponse;

  @override
  Future<StaffDashboardSummary> getDashboardSummary() async {
    summaryCalls += 1;
    if (summaryError != null) {
      throw summaryError!;
    }
    return _summary;
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getRecentReports({
    int size = 5,
  }) async {
    recentCalls += 1;
    if (recentError != null) {
      throw recentError!;
    }
    if (recentReportsPage != null) {
      return recentReportsPage!;
    }
    return sampleReportsPage(totalElements: 1);
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    int? citizenId,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    assignedCalls.add(
      ReportRepositoryCall(
        page: page,
        size: size,
        search: search,
        status: status,
        categoryId: categoryId,
        citizenId: citizenId,
        createdFrom: createdFrom,
        createdTo: createdTo,
      ),
    );
    if (assignedError != null) {
      throw assignedError!;
    }
    if (_pages.isEmpty) {
      return sampleReportsPage(content: const [], page: page, last: true);
    }
    return _pages.removeAt(0);
  }

  @override
  Future<CitizenReportDetail> getAssignedReport(int id) async {
    detailCalls.add(id);
    if (detailError != null) {
      throw detailError!;
    }
    return assignedReportDetail ?? sampleReportDetail(id: id);
  }

  @override
  Future<CitizenReportDetail> updateAssignedReportStatus(
    int id,
    ReportStatus status,
  ) async {
    statusUpdateCalls.add((id: id, status: status));
    if (updateStatusError != null) {
      throw updateStatusError!;
    }
    if (pendingUpdateStatusResponse != null) {
      return pendingUpdateStatusResponse!;
    }
    return sampleReportDetail(id: id, status: status);
  }
}

CitizenNotification sampleCitizenNotification({
  int id = 1,
  bool isRead = false,
  int? reportId = 12,
}) {
  return CitizenNotification(
    id: id,
    type: CitizenNotificationType.reportAssigned,
    title: 'Report assigned',
    message: 'Your report was assigned to Public Works.',
    reportId: reportId,
    isRead: isRead,
    createdAt: DateTime.parse('2026-07-20T10:15:00'),
  );
}

StaffDashboardSummary sampleStaffSummary() {
  return const StaffDashboardSummary(
    pendingReports: 1,
    receivedReports: 2,
    inProgressReports: 3,
    resolvedReports: 4,
    rejectedReports: 0,
    cancelledReports: 0,
    totalAssigned: 10,
  );
}

CitizenReportSummary sampleReport({
  int id = 1,
  String title = 'Broken sidewalk',
  String address = '12 Nguyen Hue',
  ReportStatus status = ReportStatus.pending,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return CitizenReportSummary(
    id: id,
    title: title,
    address: address,
    status: status,
    categoryId: 7,
    categoryName: 'Roads',
    departmentId: null,
    departmentName: null,
    citizenId: 1,
    citizenName: 'Nguyen Minh Anh',
    primaryImageUrl: null,
    createdAt: createdAt ?? DateTime.parse('2026-07-20T10:15:00'),
    updatedAt: updatedAt ?? DateTime.parse('2026-07-20T10:15:00'),
  );
}

ReportsPage<CitizenReportSummary> sampleReportsPage({
  List<CitizenReportSummary>? content,
  int page = 0,
  bool last = true,
  int? totalElements,
}) {
  final reports = content ?? [sampleReport()];
  return ReportsPage(
    content: reports,
    page: page,
    size: 10,
    totalElements: totalElements ?? reports.length,
    totalPages: last ? page + 1 : page + 2,
    first: page == 0,
    last: last,
  );
}

CitizenReportDetail sampleReportDetail({
  int id = 12,
  String title = 'Broken sidewalk',
  String description = 'Uneven pavement near the bus stop.',
  String address = '12 Nguyen Hue',
  ReportStatus status = ReportStatus.pending,
}) {
  return CitizenReportDetail(
    id: id,
    title: title,
    description: description,
    address: address,
    status: status,
    latitude: 10.77,
    longitude: 106.7,
    categoryId: 7,
    categoryName: 'Roads',
    citizenId: 1,
    citizenName: 'Nguyen Minh Anh',
    images: const [],
    createdAt: DateTime.parse('2026-07-20T10:15:00'),
    updatedAt: DateTime.parse('2026-07-20T10:15:00'),
  );
}
