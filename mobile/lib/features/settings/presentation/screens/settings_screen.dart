import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasAiKey = false;

  @override
  void initState() {
    super.initState();
    _checkAiKey();
  }

  Future<void> _checkAiKey() async {
    final has = await AppServices.instance.ai.hasKey();
    if (mounted) setState(() => _hasAiKey = has);
  }

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
      if (context.mounted) context.go('/login');
    }
  }

  void _openAiKeySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AiKeySheet(
        hasKey: _hasAiKey,
        onSaved: () {
          if (mounted) setState(() => _hasAiKey = true);
        },
        onDeleted: () {
          if (mounted) setState(() => _hasAiKey = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile'),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.psychology_outlined,
              color: _hasAiKey ? AppColors.primary : null,
            ),
            title: const Text('AI Assistant (OpenAI key)'),
            subtitle: Text(
              _hasAiKey
                  ? 'Key saved — AI features active'
                  : 'Add your key to enable AI insights',
              style: TextStyle(
                fontSize: 12,
                color:
                    _hasAiKey ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasAiKey)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: _openAiKeySheet,
          ),
          const Divider(indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(Icons.sms_outlined),
            title: Text('SMS & notification permissions'),
            subtitle: Text('Manage automatic transaction detection'),
          ),
          const ListTile(
            leading: Icon(Icons.fingerprint_rounded),
            title: Text('Biometric lock'),
            subtitle: Text('Face ID / Touch ID / Fingerprint'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & data controls'),
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _AiKeySheet extends StatefulWidget {
  const _AiKeySheet({
    required this.hasKey,
    required this.onSaved,
    required this.onDeleted,
  });

  final bool hasKey;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  @override
  State<_AiKeySheet> createState() => _AiKeySheetState();
}

class _AiKeySheetState extends State<_AiKeySheet> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _isSaving = true);
    await AppServices.instance.ai.saveKey(key);
    widget.onSaved();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI key saved — insights unlocked!')),
      );
    }
  }

  Future<void> _delete() async {
    await AppServices.instance.ai.deleteKey();
    widget.onDeleted();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('AI Assistant Setup',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'PennyWise uses your own OpenAI key to generate personalised insights, '
              'spending analysis, and savings recommendations.\n\n'
              'Your key is stored securely on your device and never sent to our servers. '
              'Get a free key at platform.openai.com → API keys.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Key'),
          ),
          if (widget.hasKey) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _delete,
              child: const Text('Remove saved key',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ],
      ),
    );
  }
}
