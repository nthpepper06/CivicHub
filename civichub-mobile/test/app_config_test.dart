import 'package:civichub_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses localhost backend for Flutter Web by default', () {
    expect(AppConfig.apiBaseUrlFor(isWeb: true), 'http://localhost:8080');
  });

  test('uses Android emulator loopback backend by default off Web', () {
    expect(AppConfig.apiBaseUrlFor(isWeb: false), 'http://10.0.2.2:8080');
  });
}
