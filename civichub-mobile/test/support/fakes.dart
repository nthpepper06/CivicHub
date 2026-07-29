import 'package:civichub_mobile/core/storage/auth_token_storage.dart';
import 'package:civichub_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:civichub_mobile/features/auth/data/models/login_request.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_session.dart';
import 'package:civichub_mobile/features/auth/domain/models/citizen_profile.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_category.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_summary.dart';
import 'package:civichub_mobile/features/reports/domain/models/reports_page.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';

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
    this.loginFuture,
    this.currentUserFuture,
  });

  final LoginResponse? loginResponse;
  final CitizenProfile? currentUserResponse;
  final Object? loginError;
  final Object? currentUserError;
  final Future<LoginResponse>? loginFuture;
  final Future<CitizenProfile>? currentUserFuture;
  int loginCalls = 0;
  int currentUserCalls = 0;

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
  Object? error;
  Object? categoryError;
  Object? createError;
  Object? detailError;
  Future<ReportsPage<CitizenReportSummary>>? pendingResponse;
  Future<CitizenReportDetail>? pendingCreateResponse;
  Future<CitizenReportDetail>? pendingDetailResponse;

  @override
  Future<List<ReportCategory>> getCategories() async {
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
    this.sortBy,
    this.direction,
  });

  final int page;
  final int size;
  final String? search;
  final ReportStatus? status;
  final int? categoryId;
  final String? sortBy;
  final String? direction;
}

CitizenReportSummary sampleReport({
  int id = 1,
  String title = 'Broken sidewalk',
  String address = '12 Nguyen Hue',
  ReportStatus status = ReportStatus.pending,
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
    createdAt: DateTime.parse('2026-07-20T10:15:00'),
    updatedAt: DateTime.parse('2026-07-20T10:15:00'),
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
