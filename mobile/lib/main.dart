import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/app_services.dart';
import 'core/services/sms/sms_capture_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.init();
  await configureDependencies();

  if (!kIsWeb && Platform.isAndroid) {
    unawaited(sl<SmsCaptureService>().startListening());
  }

  // When the landing page signs in, it passes tokens in the URL fragment:
  //   ./index.html#at=ACCESS_TOKEN&rt=REFRESH_TOKEN
  // Flutter reads them here and stores them via flutter_secure_storage so that
  // the splash screen's hasSession() check succeeds immediately.
  if (kIsWeb) {
    try {
      // Fragment from landing page is "/?at=TOKEN&rt=TOKEN" (prefixed with /? so
      // go_router routes to "/" rather than treating the token as a route name).
      final fragment = Uri.base.fragment;
      final qi = fragment.indexOf('?');
      if (qi != -1) {
        final params = Uri.splitQueryString(fragment.substring(qi + 1));
        final at = params['at'];
        final rt = params['rt'];
        if (at != null && at.isNotEmpty && rt != null && rt.isNotEmpty) {
          await AppServices.instance.tokenStorage.saveTokens(
            accessToken: at,
            refreshToken: rt,
          );
        }
      }
    } catch (_) {}
  }

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
