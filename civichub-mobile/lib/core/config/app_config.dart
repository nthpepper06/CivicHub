import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    return apiBaseUrlFor(isWeb: kIsWeb);
  }

  static String apiBaseUrlFor({required bool isWeb}) {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }
    return isWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
