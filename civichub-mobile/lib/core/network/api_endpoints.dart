class ApiEndpoints {
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';
  static const categories = '/api/categories';
  static const reports = '/api/reports';
  static const myReports = '/api/reports/my';
  static const notifications = '/api/notifications';
  static const unreadNotificationCount = '/api/notifications/unread-count';

  static String myReportDetail(int id) => '/api/reports/my/$id';
  static String myReportCancel(int id) => '/api/reports/my/$id/cancel';
  static String markNotificationRead(int id) => '/api/notifications/$id/read';
}
