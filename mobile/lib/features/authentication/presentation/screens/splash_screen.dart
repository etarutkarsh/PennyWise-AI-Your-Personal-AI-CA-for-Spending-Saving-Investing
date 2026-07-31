import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.accessToken, this.refreshToken});

  final String? accessToken;
  final String? refreshToken;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // If the landing page passed tokens via URL params, store them first.
    final at = widget.accessToken;
    final rt = widget.refreshToken;
    if (at != null && at.isNotEmpty && rt != null && rt.isNotEmpty) {
      await AppServices.instance.tokenStorage.saveTokens(
        accessToken: at,
        refreshToken: rt,
      );
    }

    if (!mounted) return;
    final hasSession = await AppServices.instance.auth.hasSession();
    if (!mounted) return;
    context.go(hasSession ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_rounded, color: AppColors.primary, size: 72),
            SizedBox(height: 16),
            Text(
              'PennyWise AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Personal AI CA',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
