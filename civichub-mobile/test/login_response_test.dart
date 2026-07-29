import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> validLoginJson({Map<String, dynamic>? user}) {
  return {
    'accessToken': 'jwt-token',
    'tokenType': 'Bearer',
    'expiresIn': 86400,
    'user':
        user ??
        {
          'id': 1,
          'fullName': 'Nguyen Minh Anh',
          'email': 'minh.anh@civichub.vn',
          'role': 'CITIZEN',
          'status': 'ACTIVE',
          'isActive': true,
        },
  };
}

void main() {
  test('Login response parses CITIZEN user', () {
    final response = LoginResponse.fromJson(validLoginJson());

    expect(response.accessToken, 'jwt-token');
    expect(response.user.role, UserRole.citizen);
  });

  test('Login response missing accessToken fails', () {
    final json = validLoginJson()..remove('accessToken');

    expect(
      () => LoginResponse.fromJson(json),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('Login response blank accessToken fails', () {
    final json = validLoginJson()..['accessToken'] = '   ';

    expect(() => LoginResponse.fromJson(json), throwsA(isA<ApiException>()));
  });

  test('Login response missing required user fields fails', () {
    final json = validLoginJson(user: {'id': 1, 'role': 'CITIZEN'});

    expect(() => LoginResponse.fromJson(json), throwsA(isA<ApiException>()));
  });

  test('Current user missing id email or role fails', () {
    expect(
      () => citizenProfileFromJson({'email': 'citizen@civichub.vn'}),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => citizenProfileFromJson({'id': 1, 'role': 'CITIZEN'}),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => citizenProfileFromJson({'id': 1, 'email': 'citizen@civichub.vn'}),
      throwsA(isA<ApiException>()),
    );
  });

  test('Invalid role does not fallback to CITIZEN', () {
    expect(
      () => citizenProfileFromJson({
        'id': 1,
        'email': 'citizen@civichub.vn',
        'role': 'MAYOR',
      }),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });
}
