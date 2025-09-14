import 'package:airdrop_flow/features/socials/view/social_management_page.dart';
import 'package:airdrop_flow/features/wallets/view/wallet_management_page.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart'; // <-- Ganti import ini
import 'package:airdrop_flow/features/templates/view/template_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSecurityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySetting();
  }

  void _loadSecuritySetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSecurityEnabled = prefs.getBool('isSecurityEnabled') ?? false;
    });
  }

  void _toggleSecurity(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final securityService = ref.read(securityServiceProvider);

    // Periksa apakah perangkat mendukung biometrik sebelum mengaktifkan
    if (value && !await securityService.canUseBiometrics) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat tidak mendukung biometrik.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    await prefs.setBool('isSecurityEnabled', value);
    setState(() {
      _isSecurityEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Manajemen')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Manajemen Wallet'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Manajemen Akun Sosial'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SocialManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_copy_outlined),
            title: const Text('Manajemen Template Tugas'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplateManagementPage(),
                ),
              );
            },
          ),
          const Divider(),
          // Tombol Switch untuk Kunci Aplikasi
          SwitchListTile(
            title: const Text('Kunci Aplikasi'),
            subtitle: const Text('Gunakan sidik jari / Face ID saat membuka aplikasi.'),
            value: _isSecurityEnabled,
            onChanged: _toggleSecurity,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: const Text('Logout'),
            onTap: () async {
              // `authServiceProvider` kini diimpor dari firebase_providers.dart
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}
