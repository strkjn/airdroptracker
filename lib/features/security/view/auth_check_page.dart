import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Gunakan FutureProvider untuk menangani proses async dengan lebih baik
final authCheckProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isSecurityEnabled = prefs.getBool('isSecurityEnabled') ?? false;

  if (isSecurityEnabled) {
    final securityService = ref.read(securityServiceProvider);
    // Pastikan perangkat mendukung biometrik sebelum mencoba
    if (await securityService.canUseBiometrics) {
      return await securityService.authenticate(
        reason: 'Autentikasi untuk membuka Airdrop Flow',
      );
    }
  }
  // Jika keamanan tidak aktif atau biometrik tidak didukung, anggap berhasil
  return true;
});

class AuthCheckPage extends ConsumerWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau status dari FutureProvider
    final authCheck = ref.watch(authCheckProvider);

    return authCheck.when(
      // 1. Saat proses autentikasi berjalan, tampilkan loading
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      // 2. Jika ada error (misal: pengguna membatalkan), tampilkan pesan
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Autentikasi Gagal'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Beri pengguna opsi untuk mencoba lagi
                  ref.invalidate(authCheckProvider);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      // 3. Jika berhasil, lanjutkan ke halaman utama
      data: (isAuthenticated) {
        if (isAuthenticated) {
          // Gunakan 'postFrameCallback' untuk memastikan navigasi aman
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
          });
          // Tampilkan container kosong sementara navigasi diproses
          return const Scaffold(body: SizedBox.shrink());
        }
        // Jika autentikasi gagal atau dibatalkan, tampilkan UI error
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