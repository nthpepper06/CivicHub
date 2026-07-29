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
import '../features/reports/data/datasources/reports_remote_data_source.dart';
import '../features/reports/data/repositories/reports_repository_impl.dart';
import '../features/reports/domain/repositories/reports_repository.dart';
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<LoginCubit>.value(value: _loginCubit),
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
