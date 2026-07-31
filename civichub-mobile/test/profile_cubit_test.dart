import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/models/profile_update_request.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:civichub_mobile/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:civichub_mobile/features/profile/presentation/cubit/edit_profile_state.dart';
import 'package:civichub_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:civichub_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Profile loading succeeds and synchronizes AuthCubit', () async {
    final remote = FakeAuthRemoteDataSource(
      currentUserResponse: sampleUser().copyWith(fullName: 'Updated Name'),
    );
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: MemoryAuthTokenStorage(),
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = ProfileCubit(
      authRepository: repository,
      authCubit: authCubit,
    );

    await cubit.load();

    expect(cubit.state.status, ProfileStatus.success);
    expect(cubit.state.user?.fullName, 'Updated Name');
    expect(authCubit.state.user?.fullName, 'Updated Name');
  });

  test(
    'Profile empty can be represented when no initial user is available',
    () {
      final repository = AuthRepositoryImpl(
        remoteDataSource: FakeAuthRemoteDataSource(),
        tokenStorage: MemoryAuthTokenStorage(),
      );
      final authCubit = AuthCubit(authRepository: repository);
      final cubit = ProfileCubit(
        authRepository: repository,
        authCubit: authCubit,
      );

      expect(cubit.state.user, isNull);
      expect(cubit.state.status, ProfileStatus.initial);
    },
  );

  test('Profile failure and retry', () async {
    final remote = FakeAuthRemoteDataSource(
      currentUserError: ApiException.network,
    );
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: MemoryAuthTokenStorage(),
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = ProfileCubit(
      authRepository: repository,
      authCubit: authCubit,
    );

    await cubit.load();
    expect(cubit.state.status, ProfileStatus.failure);
    expect(cubit.state.errorMessage, contains('Cannot load your profile'));

    remote.currentUserError = null;
    await cubit.retry();
    expect(cubit.state.status, ProfileStatus.success);
  });

  test('Profile pull-to-refresh reloads user', () async {
    final remote = FakeAuthRemoteDataSource();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: MemoryAuthTokenStorage(),
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = ProfileCubit(
      authRepository: repository,
      authCubit: authCubit,
      initialUser: sampleUser(),
    );

    await cubit.refresh();

    expect(remote.currentUserCalls, 1);
    expect(cubit.state.isRefreshing, isFalse);
  });

  test(
    'Edit profile update success refreshes AuthCubit session user',
    () async {
      final remote = FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        tokenStorage: MemoryAuthTokenStorage(),
      );
      final authCubit = AuthCubit(authRepository: repository);
      authCubit.setAuthenticated(sampleUser());
      final cubit = EditProfileCubit(
        authRepository: repository,
        authCubit: authCubit,
      );

      await cubit.submit(
        const ProfileUpdateRequest(
          fullName: ' New Citizen ',
          phone: ' 123 ',
          avatar: ' https://example.com/avatar.png ',
        ),
      );

      expect(cubit.state.status, EditProfileStatus.success);
      expect(authCubit.state.status, AuthStatus.authenticated);
      expect(authCubit.state.user?.fullName, 'New Citizen');
      expect(remote.profileUpdateRequests.single.toJson(), {
        'fullName': 'New Citizen',
        'phone': '123',
        'avatar': 'https://example.com/avatar.png',
      });
    },
  );

  test(
    'Edit profile update failure preserves authenticated session user',
    () async {
      final remote = FakeAuthRemoteDataSource(
        updateUserError: ApiException.server,
      );
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        tokenStorage: MemoryAuthTokenStorage(),
      );
      final authCubit = AuthCubit(authRepository: repository);
      authCubit.setAuthenticated(sampleUser());
      final cubit = EditProfileCubit(
        authRepository: repository,
        authCubit: authCubit,
      );

      await cubit.submit(const ProfileUpdateRequest(fullName: 'New Citizen'));

      expect(cubit.state.status, EditProfileStatus.failure);
      expect(authCubit.state.user?.fullName, 'Nguyen Minh Anh');
    },
  );

  test('Edit profile prevents double submit', () async {
    final completer = Completer<Never>();
    final remote = FakeAuthRemoteDataSource(updateUserFuture: completer.future);
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: MemoryAuthTokenStorage(),
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = EditProfileCubit(
      authRepository: repository,
      authCubit: authCubit,
    );

    final first = cubit.submit(
      const ProfileUpdateRequest(fullName: 'New Citizen'),
    );
    final second = cubit.submit(
      const ProfileUpdateRequest(fullName: 'New Citizen'),
    );
    await Future<void>.delayed(Duration.zero);
    completer.completeError(StateError('unused'));
    await first;
    await second;

    expect(remote.updateUserCalls, 1);
  });
}
