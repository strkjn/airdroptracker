import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authCheckProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isSecurityEnabled = prefs.getBool('isSecurityEnabled') ?? false;

  // Jika keamanan tidak diaktifkan, langsung berikan akses.
  if (!isSecurityEnabled) {
    return true;
  }

  final securityService = ref.read(securityServiceProvider);
  final canUseBiometrics = await securityService.canUseBiometrics;

  // Jika perangkat sama sekali tidak mendukung biometrik,
  // berikan akses untuk mencegah pengguna terkunci.
  if (!canUseBiometrics) {
    return true;
  }

  // Jika perangkat mendukung, lanjutkan dengan proses autentikasi
  // (yang sekarang sudah mendukung fallback ke PIN/Pola).
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
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