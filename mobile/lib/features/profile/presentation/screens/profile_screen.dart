import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await AppServices.instance.user.getMe();
      if (mounted) setState(() => _user = user);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editSalary() async {
    final controller = TextEditingController(
      text: _user?.monthlyIncome?.toStringAsFixed(0) ?? '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update monthly salary'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'e.g. 75000',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        final updated = await AppServices.instance.user.updateMe(monthlyIncome: result);
        setState(() => _user = updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salary updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _editRiskAppetite() async {
    const options = ['low', 'medium', 'high'];
    const labels = {
      'low': '🟢 Low — FDs and bonds',
      'medium': '🟡 Medium — Mutual funds',
      'high': '🔴 High — Equity & stocks',
    };
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Risk appetite'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o),
                  child: Text(labels[o]!),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      try {
        final updated =
            await AppServices.instance.user.updateMe(riskAppetite: result);
        setState(() => _user = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AppServices.instance.auth.logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Avatar + name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              (_user?.fullName.isNotEmpty == true)
                                  ? _user!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _user?.fullName ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _user?.email ?? '',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_user?.userType ?? '')
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Financial settings
                    const Text(
                      'Financial Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.currency_rupee_rounded,
                                color: AppColors.primary),
                            title: const Text('Monthly Salary'),
                            subtitle: Text(
                              _user?.monthlyIncome != null
                                  ? '₹${_user!.monthlyIncome!.toStringAsFixed(0)}'
                                  : 'Not set',
                            ),
                            trailing:
                                const Icon(Icons.chevron_right_rounded),
                            onTap: _editSalary,
                          ),
                          const Divider(height: 0, indent: 16),
                          ListTile(
                            leading: const Icon(Icons.trending_up_rounded,
                                color: AppColors.accent),
                            title: const Text('Risk Appetite'),
                            subtitle: Text({
                                  'low': 'Low — FDs and bonds',
                                  'medium': 'Medium — Mutual funds',
                                  'high': 'High — Equity & stocks',
                                }[_user?.riskAppetite ?? ''] ??
                                'Not set'),
                            trailing:
                                const Icon(Icons.chevron_right_rounded),
                            onTap: _editRiskAppetite,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded,
                            color: AppColors.danger),
                        title: const Text(
                          'Log out',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        onTap: _logout,
                      ),
                    ),
                  ],
                ),
    );
  }
}
