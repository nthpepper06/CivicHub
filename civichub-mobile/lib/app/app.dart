import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routing/app_router.dart';

class CivicHubApp extends StatelessWidget {
  const CivicHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CivicHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
