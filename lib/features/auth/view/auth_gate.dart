import 'package:airdrop_flow/features/security/view/auth_check_page.dart'; // <-- IMPORT BARU
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:airdrop_flow/features/auth/view/login_page.dart';
// Hapus import MainScaffold karena sudah tidak digunakan di sini
// import 'package:airdrop_flow/features/dashboard/view/main_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Arahkan ke AuthCheckPage setelah login
          return const AuthCheckPage();
        }

        return const LoginPage();
      },
    );
  }
}
