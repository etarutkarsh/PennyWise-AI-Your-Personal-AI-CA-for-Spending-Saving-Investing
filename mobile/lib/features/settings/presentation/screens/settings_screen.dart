import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          const ListTile(
            leading: Icon(Icons.sms_outlined),
            title: Text('SMS & notification permissions'),
            subtitle: Text('Manage automatic transaction detection sources'),
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
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Log out'),
            onTap: () {
              // TODO: TokenStorage.clear() then context.go('/login');
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
