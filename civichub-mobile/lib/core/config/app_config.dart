import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const bool _isProductBuild = bool.fromEnvironment('dart.vm.product');

  static String get environment => _environment.trim().toLowerCase();

  static String get apiBaseUrl {
    return apiBaseUrlFor(isWeb: kIsWeb);
  }

  static String apiBaseUrlFor({
    required bool isWeb,
    String? environment,
    String? apiBaseUrlOverride,
    bool? isProductBuild,
  }) {
    final env = (environment ?? AppConfig.environment).trim().toLowerCase();
    final override = (apiBaseUrlOverride ?? _apiBaseUrlOverride).trim();
    final productBuild = isProductBuild ?? _isProductBuild;
    if (override.isNotEmpty) {
      return override;
    }

    if (env == 'development' || env.isEmpty) {
      if (productBuild) {
        throw StateError('API_BASE_URL is required for production builds.');
      }
      return isWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    }

    if (env == 'staging' || env == 'production') {
      throw StateError('API_BASE_URL is required when APP_ENV is $env.');
    }

    throw StateError(
      'Unsupported APP_ENV "$env". Use development, staging, or production.',
    );
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
