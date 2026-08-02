import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  // Step 1 — phone entry
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  // Step 2 — 6-box OTP entry
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFoci = List.generate(6, (_) => FocusNode());

  bool _step2 = false;
  bool _loading = false;
  String? _maskedPhone;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    for (final c in _otpCtrls) { c.dispose(); }
    for (final f in _otpFoci) { f.dispose(); }
    super.dispose();
  }

  String get _e164 => '+91${_phoneCtrl.text.trim()}';

  // ── Step 1: Send OTP ────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final raw = _phoneCtrl.text.trim();
    if (raw.length != 10 || int.tryParse(raw) == null) {
      _snack('Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _loading = true);
    try {
      final devOtp = await AppServices.instance.auth.sendOtp(_e164);
      setState(() {
        _step2 = true;
        _maskedPhone = '+91 ${raw.substring(0, 5)} ${raw.substring(5)}';
        _loading = false;
      });
      // In dev mode auto-fill the OTP boxes from the response
      if (devOtp != null && devOtp.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpCtrls[i].text = devOtp[i];
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFoci[devOtp != null ? 5 : 0].requestFocus();
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack(friendlyError(e));
    }
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length != 6) {
      _snack('Enter the complete 6-digit OTP.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AppServices.instance.auth.verifyOtp(_e164, otp);
      // Sync salary from backend profile
      try {
        final user = await AppServices.instance.user.getMe();
        if ((user.monthlyIncome ?? 0) > 0) {
          await UserPrefsStorage.saveSalary(user.monthlyIncome!);
        }
      } catch (_) {}
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _loading = false);
      _snack(friendlyError(e));
    }
  }

  void _resetToStep1() {
    for (final c in _otpCtrls) { c.clear(); }
    setState(() { _step2 = false; _loading = false; });
    WidgetsBinding.instance.addPostFrameCallback((_) => _phoneFocus.requestFocus());
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: _step2 ? _resetToStep1 : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _step2
                ? _OtpStep(
                    key: const ValueKey('step2'),
                    maskedPhone: _maskedPhone ?? '',
                    ctrls: _otpCtrls,
                    foci: _otpFoci,
                    loading: _loading,
                    onVerify: _verifyOtp,
                    onReset: _resetToStep1,
                  )
                : _PhoneStep(
                    key: const ValueKey('step1'),
                    ctrl: _phoneCtrl,
                    focus: _phoneFocus,
                    loading: _loading,
                    onSend: _sendOtp,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Step 1 widget ─────────────────────────────────────────────────────────────

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.ctrl,
    required this.focus,
    required this.loading,
    required this.onSend,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '📱  PHONE LOGIN',
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
          'Enter your\nmobile number.',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll send a one-time password to verify it's you.",
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 44),

        // Phone input with +91 prefix
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE8ECF0)),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  focusNode: focus,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => onSend(),
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: '00000 00000',
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: loading ? null : onSend,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Send OTP',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'By continuing, you agree to receive an SMS with a\none-time password on this number.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ── Step 2 widget ─────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.maskedPhone,
    required this.ctrls,
    required this.foci,
    required this.loading,
    required this.onVerify,
    required this.onReset,
  });

  final String maskedPhone;
  final List<TextEditingController> ctrls;
  final List<FocusNode> foci;
  final bool loading;
  final VoidCallback onVerify;
  final VoidCallback onReset;

  void _onBoxInput(int i, String val, BuildContext context) {
    // Strip non-digits and take only first character
    final digit = val.replaceAll(RegExp(r'\D'), '');
    ctrls[i].text = digit.isNotEmpty ? digit[0] : '';
    ctrls[i].selection = TextSelection.fromPosition(
      TextPosition(offset: ctrls[i].text.length),
    );
    if (digit.isNotEmpty && i < 5) foci[i + 1].requestFocus();
  }

  void _onKeyDown(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        ctrls[i].text.isEmpty &&
        i > 0) {
      foci[i - 1].requestFocus();
    }
  }

  void _onPaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    final count = digits.length.clamp(0, 6);
    for (int j = 0; j < count; j++) {
      ctrls[j].text = digits[j];
    }
    if (count > 0) foci[(count - 1).clamp(0, 5)].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '✅  OTP SENT',
            style: GoogleFonts.dmSans(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter the\n6-digit code.',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: maskedPhone,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),

        // 6 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _OtpBox(
            ctrl: ctrls[i],
            focus: foci[i],
            onChanged: (v) => _onBoxInput(i, v, context),
            onKey: (e) => _onKeyDown(i, e),
            onPaste: _onPaste,
          )),
        ),
        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: loading ? null : onVerify,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Verify & Sign in',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onReset,
            child: Text(
              '← Change number / Resend OTP',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.ctrl,
    required this.focus,
    required this.onChanged,
    required this.onKey,
    required this.onPaste,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;
  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 58,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: ctrl,
          focusNode: focus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          onTap: () {
            // Select all on tap so next digit replaces cleanly
            ctrl.selection = TextSelection(
              baseOffset: 0,
              extentOffset: ctrl.text.length,
            );
          },
          style: GoogleFonts.spaceMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: ctrl.text.isEmpty
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ctrl.text.isEmpty
                    ? const Color(0xFFE8ECF0)
                    : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
