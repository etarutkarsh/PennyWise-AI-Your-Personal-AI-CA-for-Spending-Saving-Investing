import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// TODO(Phase 1 wiring): initialize Firebase (firebase_core), Hive
// (hive_flutter) and register the ApiClient/TokenStorage/repositories with
// a service locator or provider tree before runApp. Left out of this
// scaffold so the app builds without requiring Firebase project config.
void main() {
  runApp(const PennyWiseApp());
}

class PennyWiseApp extends StatelessWidget {
  const PennyWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PennyWise AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
