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

  static String reportDetailPath(int id) => '$reportDetail/$id';
  static String editReportPath(int id) => '$editReport/$id';
}
