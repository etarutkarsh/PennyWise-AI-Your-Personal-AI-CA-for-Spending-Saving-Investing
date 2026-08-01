import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/redirect_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            'You will need to log in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppServices.instance.auth.logout();
      if (context.mounted && !redirectToLanding()) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Profile'),
            subtitle: const Text('Edit name, salary, risk appetite'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile'),
          ),
          const Divider(indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.psychology_outlined, color: AppColors.primary),
            title: Text('AI Assistant'),
            subtitle: Text(
              'Active — powered by PennyWise AI',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
            trailing: Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
          ),

          // ── Finance ───────────────────────────────────────────────────────
          const _SectionHeader('Finance'),
          ListTile(
            leading: const Icon(Icons.savings_outlined, color: AppColors.primary),
            title: const Text('Savings Rules'),
            subtitle: const Text('Automate round-ups, sweeps & fixed saves'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/savings-rules'),
          ),

          // ── Privacy & Security ────────────────────────────────────────────
          const _SectionHeader('Privacy & Security'),
          const ListTile(
            leading: Icon(Icons.sms_outlined),
            title: Text('SMS & notification permissions'),
            subtitle: Text('Manage automatic transaction detection'),
          ),
          const Divider(indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.fingerprint_rounded),
            title: Text('Biometric lock'),
            subtitle: Text('Face ID / Touch ID / Fingerprint'),
          ),
          const Divider(indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & data controls'),
          ),

          // ── About ─────────────────────────────────────────────────────────
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.blue),
            title: const Text('About PennyWise'),
            subtitle: const Text('Our story, mission & roadmap'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/about'),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded, color: AppColors.indigo),
            title: const Text('Contact Us'),
            subtitle: const Text('Support, feedback & partnerships'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/contact'),
          ),

          // ── Danger zone ───────────────────────────────────────────────────
          const _SectionHeader('Account Actions'),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

