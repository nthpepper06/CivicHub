import 'package:civichub_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses localhost backend for Flutter Web by default', () {
    expect(
      AppConfig.apiBaseUrlFor(isWeb: true, environment: 'development'),
      'http://localhost:8080',
    );
  });

  test('uses Android emulator loopback backend by default off Web', () {
    expect(
      AppConfig.apiBaseUrlFor(isWeb: false, environment: 'development'),
      'http://10.0.2.2:8080',
    );
  });

  test('does not silently use local URLs in production builds', () {
    expect(
      () => AppConfig.apiBaseUrlFor(
        isWeb: true,
        environment: 'development',
        isProductBuild: true,
      ),
      throwsStateError,
    );
  });

  test('uses configured API base URL for staging and production', () {
    expect(
      AppConfig.apiBaseUrlFor(
        isWeb: true,
        environment: 'production',
        apiBaseUrlOverride: ' https://api.civichub.example ',
      ),
      'https://api.civichub.example',
    );
  });

  test('fails safely when staging or production API URL is omitted', () {
    expect(
      () => AppConfig.apiBaseUrlFor(isWeb: true, environment: 'staging'),
      throwsStateError,
    );
    expect(
      () => AppConfig.apiBaseUrlFor(isWeb: false, environment: 'production'),
      throwsStateError,
    );
  });

  test('rejects unsupported environment names', () {
    expect(
      () => AppConfig.apiBaseUrlFor(isWeb: true, environment: 'qa'),
      throwsStateError,
    );
  });
}
