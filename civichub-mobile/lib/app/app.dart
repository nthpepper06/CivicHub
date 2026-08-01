import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/storage/auth_token_storage.dart';
import '../core/storage/secure_auth_token_storage.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/login_cubit.dart';
import '../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';
import '../features/reports/data/datasources/reports_remote_data_source.dart';
import '../features/reports/data/repositories/reports_repository_impl.dart';
import '../features/reports/domain/repositories/reports_repository.dart';
import '../features/staff/data/datasources/staff_remote_data_source.dart';
import '../features/staff/data/repositories/staff_repository_impl.dart';
import '../features/staff/domain/repositories/staff_repository.dart';
import '../features/staff/presentation/cubit/staff_workspace_cubit.dart';
import 'routing/app_router.dart';

class CivicHubApp extends StatefulWidget {
  const CivicHubApp({super.key});

  @override
  State<CivicHubApp> createState() => _CivicHubAppState();
}

class _CivicHubAppState extends State<CivicHubApp> {
  late final SecureAuthTokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthRemoteDataSourceImpl _remoteDataSource;
  late final AuthRepository _authRepository;
  late final ReportsRemoteDataSourceImpl _reportsRemoteDataSource;
  late final ReportsRepository _reportsRepository;
  late final NotificationsRemoteDataSourceImpl _notificationsRemoteDataSource;
  late final NotificationsRepository _notificationsRepository;
  late final StaffRemoteDataSourceImpl _staffRemoteDataSource;
  late final StaffRepository _staffRepository;
  late final StaffWorkspaceCubit _staffWorkspaceCubit;
  late final AuthCubit _authCubit;
  late final LoginCubit _loginCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = SecureAuthTokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _remoteDataSource = AuthRemoteDataSourceImpl(apiClient: _apiClient);
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      tokenStorage: _tokenStorage,
    );
    _reportsRemoteDataSource = ReportsRemoteDataSourceImpl(
      apiClient: _apiClient,
    );
    _reportsRepository = ReportsRepositoryImpl(
      remoteDataSource: _reportsRemoteDataSource,
    );
    _notificationsRemoteDataSource = NotificationsRemoteDataSourceImpl(
      apiClient: _apiClient,
    );
    _notificationsRepository = NotificationsRepositoryImpl(
      remoteDataSource: _notificationsRemoteDataSource,
    );
    _staffRemoteDataSource = StaffRemoteDataSourceImpl(apiClient: _apiClient);
    _staffRepository = StaffRepositoryImpl(
      remoteDataSource: _staffRemoteDataSource,
    );
    _staffWorkspaceCubit = StaffWorkspaceCubit();
    _authCubit = AuthCubit(authRepository: _authRepository);
    _loginCubit = LoginCubit(
      authRepository: _authRepository,
      authCubit: _authCubit,
    );
    _apiClient.unauthorizedHandler = _authCubit;
    _router = AppRouter.create(authCubit: _authCubit);
    unawaited(_authCubit.bootstrap());
  }

  @override
  void dispose() {
    _authCubit.close();
    _loginCubit.close();
    _staffWorkspaceCubit.close();
    _apiClient.dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthTokenStorage>.value(value: _tokenStorage),
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<AuthRemoteDataSource>.value(
          value: _remoteDataSource,
        ),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ReportsRemoteDataSource>.value(
          value: _reportsRemoteDataSource,
        ),
        RepositoryProvider<ReportsRepository>.value(value: _reportsRepository),
        RepositoryProvider<NotificationsRemoteDataSource>.value(
          value: _notificationsRemoteDataSource,
        ),
        RepositoryProvider<NotificationsRepository>.value(
          value: _notificationsRepository,
        ),
        RepositoryProvider<StaffRemoteDataSource>.value(
          value: _staffRemoteDataSource,
        ),
        RepositoryProvider<StaffRepository>.value(value: _staffRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<LoginCubit>.value(value: _loginCubit),
          BlocProvider<StaffWorkspaceCubit>.value(value: _staffWorkspaceCubit),
        ],
        child: MaterialApp.router(
          title: 'CivicHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
