class ApiEndpoints {
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';
  static const authChangePassword = '/api/auth/change-password';
  static const categories = '/api/categories';
  static const reports = '/api/reports';
  static const myReports = '/api/reports/my';
  static const notifications = '/api/notifications';
  static const unreadNotificationCount = '/api/notifications/unread-count';
  static const staffDashboardSummary = '/api/staff/dashboard/summary';
  static const staffDashboardRecent = '/api/staff/dashboard/recent';
  static const staffReports = '/api/staff/reports';

  static String myReportDetail(int id) => '/api/reports/my/$id';
  static String myReportCancel(int id) => '/api/reports/my/$id/cancel';
  static String markNotificationRead(int id) => '/api/notifications/$id/read';
  static String staffReportDetail(int id) => '/api/staff/reports/$id';
  static String staffReportStatus(int id) => '/api/staff/reports/$id/status';
}
