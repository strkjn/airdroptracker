import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// --- 1. PASTIKAN IMPORT INI ADA ---
import 'package:intl/date_symbol_data_local.dart'; 
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'features/auth/view/auth_gate.dart';

final NotificationService notificationService = NotificationService();

void main() async {
  // Pastikan Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 2. PASTIKAN BARIS INISIALISASI INI ADA DAN DIJALANKAN ---
  await initializeDateFormatting('id_ID', null);

  // Memuat environment variables dari file .env
  await dotenv.load(fileName: ".env");

  // Inisialisasi notifikasi
  await notificationService.init();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Mengaktifkan cache Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airdrop Flow',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white.withAlpha(13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      ),
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}