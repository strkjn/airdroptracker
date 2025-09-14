import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart'; // <-- 1. Import service baru
import 'firebase_options.dart';
import 'features/auth/view/auth_gate.dart';

// 2. Buat instance global dari service agar bisa diakses
final NotificationService notificationService = NotificationService();

void main() async {
  // Pastikan semua binding framework siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Inisialisasi service notifikasi saat aplikasi dimulai
  await notificationService.init();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airdrop Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}