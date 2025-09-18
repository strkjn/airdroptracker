// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'features/auth/view/auth_gate.dart';

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
  await notificationService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    const Color primaryColor = Color(0xFFA9FF58);
    
    // --- PENYESUAIAN EFEK KACA DI SINI ---
    // Opasitas warna latar belakang kartu ditingkatkan agar lebih terlihat
    const Color cardBackgroundColor = Color(0x2AFFFFFF); // Dari 0x1A menjadi 0x2A
    // Warna border dibuat sedikit lebih terang untuk mempertegas tepi "kaca"
    const Color cardBorderColor = Color(0x3DFFFFFF); // Dari 0x26 menjadi 0x3D
    const Color inputFillColor = Color(0x40000000);


    return MaterialApp(
      title: 'Airdrop Flow',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent, 
        
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          onPrimary: Colors.black,
          secondary: Colors.cyanAccent,
          surface: cardBackgroundColor,
          onSurface: Colors.white,
        ),
        
        cardTheme: CardThemeData(
          elevation: 0,
          color: cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: cardBorderColor, width: 1.0),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          floatingLabelStyle: const TextStyle(color: primaryColor),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          bodyMedium: TextStyle(color: Color(0xB3FFFFFF)),
          labelSmall: TextStyle(color: Color(0x99FFFFFF)),
        ),

        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}