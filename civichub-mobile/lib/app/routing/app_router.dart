import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static GoRouter create({
    required AuthCubit authCubit,
    String initialLocation = AppRoutes.splash,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final location = state.matchedLocation;
        final status = authCubit.state.status;
        final isSplash = location == AppRoutes.splash;
        final isLogin = location == AppRoutes.login;
        final isPublic = isSplash || isLogin;

        switch (status) {
          case AuthStatus.unknown:
          case AuthStatus.checking:
          case AuthStatus.failure:
            return isSplash ? null : AppRoutes.splash;
          case AuthStatus.unauthenticated:
            return isLogin ? null : AppRoutes.login;
          case AuthStatus.authenticated:
            return isPublic ? AppRoutes.home : null;
        }
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.reports,
                  builder: (context, state) => const ReportsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.notifications,
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          pageBuilder: (context, state) {
            return const MaterialPage(child: EditProfileScreen());
          },
        ),
        GoRoute(
          path: AppRoutes.createReport,
          pageBuilder: (context, state) {
            return const MaterialPage(child: CreateReportScreen());
          },
        ),
        GoRoute(
          path: '${AppRoutes.reportDetail}/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const MaterialPage(child: ReportDetailScreen(reportId: 0));
            }
            return MaterialPage(child: ReportDetailScreen(reportId: id));
          },
        ),
      ],
    );
  }
}
