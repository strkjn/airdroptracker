// lib/features/security/view/auth_check_page.dart

import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airdrop_flow/core/app_router.dart';

final authCheckProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isSecurityEnabled = prefs.getBool('isSecurityEnabled') ?? false;

  if (!isSecurityEnabled) {
    return true;
  }

  final securityService = ref.read(securityServiceProvider);
  final canUseBiometrics = await securityService.canUseBiometrics;

  if (!canUseBiometrics) {
    return true;
  }

  return await securityService.authenticate(
    reason: 'Autentikasi untuk membuka Airdrop Flow',
  );
});

class AuthCheckPage extends ConsumerWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authCheck = ref.watch(authCheckProvider);

    return authCheck.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Autentikasi Gagal'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authCheckProvider);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (isAuthenticated) {
        if (isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // --- PERUBAHAN DI SINI ---
            // Menggunakan AppRouter untuk navigasi yang lebih bersih dan aman.
            // pushReplacementNamed digunakan agar pengguna tidak bisa menekan tombol "kembali"
            // ke halaman pemeriksaan ini.
            AppRouter.goToMainScaffold(context);
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Autentikasi Dibutuhkan'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authCheckProvider),
                  child: const Text('Buka Kunci'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}