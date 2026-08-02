import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_enums.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/domain/models/report_detail.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/reports/presentation/screens/edit_report_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/staff/presentation/screens/staff_home_screen.dart';
import '../../features/staff/presentation/screens/staff_report_detail_screen.dart';
import '../../features/staff/presentation/screens/staff_reports_screen.dart';
import '../../features/staff/presentation/widgets/staff_shell.dart';
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
        final path = state.uri.path;
        final status = authCubit.state.status;
        final isSplash = location == AppRoutes.splash;
        final isLogin = location == AppRoutes.login;
        final isUnsupported = location == AppRoutes.unsupportedRole;
        final isPublic = isSplash || isLogin;

        switch (status) {
          case AuthStatus.unknown:
          case AuthStatus.checking:
          case AuthStatus.failure:
            return isSplash ? null : AppRoutes.splash;
          case AuthStatus.unauthenticated:
            return isLogin ? null : AppRoutes.login;
          case AuthStatus.authenticated:
            final role = authCubit.state.user?.role;
            return switch (role) {
              UserRole.citizen => _citizenRedirect(
                isPublic: isPublic,
                isUnsupported: isUnsupported,
                path: path,
              ),
              UserRole.staff => _staffRedirect(
                isPublic: isPublic,
                isUnsupported: isUnsupported,
                path: path,
              ),
              UserRole.admin =>
                isUnsupported ? null : AppRoutes.unsupportedRole,
              null => isUnsupported ? null : AppRoutes.unsupportedRole,
            };
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
        GoRoute(
          path: AppRoutes.unsupportedRole,
          builder: (context, state) => const _UnsupportedRoleScreen(),
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
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StaffShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.staffHome,
                  builder: (context, state) => const StaffHomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.staffReports,
                  builder: (context, state) => const StaffReportsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.staffNotifications,
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.staffProfile,
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
            final id = _parsePositiveId(state.pathParameters['id']);
            if (id == null) {
              return const MaterialPage(child: _InvalidReportRouteScreen());
            }
            return MaterialPage(
              child: ReportDetailScreen(
                reportId: id,
                focus: state.uri.queryParameters['focus'],
              ),
            );
          },
        ),
        GoRoute(
          path: '${AppRoutes.staffReportDetail}/:id',
          pageBuilder: (context, state) {
            final id = _parsePositiveId(state.pathParameters['id']);
            if (id == null) {
              return const MaterialPage(
                child: _InvalidReportRouteScreen(
                  returnRoute: AppRoutes.staffReports,
                  returnLabel: 'Return to Assigned Reports',
                ),
              );
            }
            return MaterialPage(
              child: StaffReportDetailScreen(
                reportId: id,
                focus: state.uri.queryParameters['focus'],
              ),
            );
          },
        ),
        GoRoute(
          path: '${AppRoutes.editReport}/:id',
          pageBuilder: (context, state) {
            final id = _parsePositiveId(state.pathParameters['id']);
            if (id == null) {
              return const MaterialPage(child: _InvalidReportRouteScreen());
            }
            final extra = state.extra;
            final initialReport = extra is CitizenReportDetail && extra.id == id
                ? extra
                : null;
            return MaterialPage(
              child: EditReportScreen(
                reportId: id,
                initialReport: initialReport,
              ),
            );
          },
        ),
      ],
    );
  }

  static int? _parsePositiveId(String? raw) {
    final id = int.tryParse(raw ?? '');
    if (id == null || id <= 0) {
      return null;
    }
    return id;
  }

  static String? _citizenRedirect({
    required bool isPublic,
    required bool isUnsupported,
    required String path,
  }) {
    if (isPublic || isUnsupported || path.startsWith('/staff')) {
      return AppRoutes.home;
    }
    return null;
  }

  static String? _staffRedirect({
    required bool isPublic,
    required bool isUnsupported,
    required String path,
  }) {
    if (isPublic || isUnsupported) {
      return AppRoutes.staffHome;
    }
    if (path == AppRoutes.notifications) {
      return AppRoutes.staffNotifications;
    }
    if (path == AppRoutes.profile) {
      return AppRoutes.staffProfile;
    }
    if (path == AppRoutes.editProfile || path.startsWith('/staff')) {
      return null;
    }
    return AppRoutes.staffHome;
  }
}

class _InvalidReportRouteScreen extends StatelessWidget {
  const _InvalidReportRouteScreen({
    this.returnRoute = AppRoutes.reports,
    this.returnLabel = 'Return to Reports',
  });

  final String returnRoute;
  final String returnLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invalid Report')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Invalid report link',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This report link is missing a valid report ID.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(returnRoute),
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(returnLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unsupported account')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'This account cannot use the mobile workspace',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please use the appropriate CivicHub application for this role.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.read<AuthCubit>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
