import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AppServices.instance.auth
          .login(_emailCtrl.text.trim(), _passwordCtrl.text);
      // Sync salary from backend so dashboard is correct on any device
      try {
        final user = await AppServices.instance.user.getMe();
        if ((user.monthlyIncome ?? 0) > 0) {
          await UserPrefsStorage.saveSalary(user.monthlyIncome!);
        }
      } catch (_) {}
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e),
                style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Hero text
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '💰  PENNYWISE AI',
                  style: GoogleFonts.dmSans(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your money,\nyour rules.',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your financial dashboard.',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 44),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      validator: (v) => (v?.contains('@') ?? false)
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) >= 8
                          ? null
                          : 'Minimum 8 characters',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : Text(
                                'Sign in',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
                Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
              ]),
              const SizedBox(height: 16),

              // Phone OTP button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/phone-login'),
                  icon: const Text('📱', style: TextStyle(fontSize: 18)),
                  label: Text(
                    'Continue with Phone Number',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDE2E8)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Center(
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'New here? '),
                        TextSpan(
                          text: 'Create account',
                          style: GoogleFonts.dmSans(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
