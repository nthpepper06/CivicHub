class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const reports = '/reports';
  static const createReport = '/reports/create';
  static const reportDetail = '/reports/detail';
  static const editReport = '/reports/edit';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const unsupportedRole = '/unsupported-role';
  static const staffHome = '/staff/home';
  static const staffReports = '/staff/reports';
  static const staffReportDetail = '/staff/reports/detail';
  static const staffNotifications = '/staff/notifications';
  static const staffProfile = '/staff/profile';

  static String reportDetailPath(int id) => '$reportDetail/$id';
  static String editReportPath(int id) => '$editReport/$id';
  static String staffReportDetailPath(int id) => '$staffReportDetail/$id';
}
