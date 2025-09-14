import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckPage extends ConsumerStatefulWidget {
  const AuthCheckPage({super.key});

  @override
  ConsumerState<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends ConsumerState<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isSecurityEnabled = prefs.getBool('isSecurityEnabled') ?? false;

    if (!mounted) return;

    if (isSecurityEnabled) {
      final securityService = ref.read(securityServiceProvider);
      final isAuthenticated = await securityService.authenticate(
        reason: 'Autentikasi untuk membuka Airdrop Flow',
      );
      if (isAuthenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan layar loading saat proses pemeriksaan
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
