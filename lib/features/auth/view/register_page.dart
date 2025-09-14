import 'package:airdrop_flow/core/providers/firebase_providers.dart'; // Menggunakan provider yang sudah ada
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT BARU
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  await ref
                      .read(authServiceProvider)
                      .signUp(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                  // Kembali ke halaman login setelah berhasil mendaftar
                  navigator.pop();

                } on FirebaseAuthException catch (e) {
                  // Menangkap error spesifik dari Firebase Auth
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mendaftar: ${e.message ?? "Terjadi kesalahan."}'),
                    ),
                  );
                } catch (e) {
                  // Menangkap error umum lainnya
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}