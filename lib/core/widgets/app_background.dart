// lib/core/widgets/app_background.dart

import 'package:flutter/material.dart';
import 'dart:ui';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const Color baseColor = Color(0xFF16171B);
    final size = MediaQuery.of(context).size;

    return Container(
      color: baseColor,
      child: Stack(
        children: [
          // Pendaran cahaya UNGU dari KIRI ATAS
          Positioned(
            left: -size.width * 0.7, // Dibuat lebih ke kiri
            top: -size.height * 0.6, // Dibuat lebih ke atas
            child: Container(
              // --- UKURAN DIPERBESAR SECARA SIGNIFIKAN ---
              height: size.height * 1.5,
              width: size.width * 2.0,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    // --- OPASITAS DITINGKATKAN LAGI ---
                    Color.fromARGB(153, 106, 26, 255), // Dari 0x88 menjadi 0x99
                    Color.fromARGB(0, 118, 103, 255),
                  ],
                ),
              ),
            ),
          ),
          
          // Pendaran cahaya HIJAU dari KANAN TENGAH
          Positioned(
            right: -size.width * 0.8, // Dibuat lebih ke kanan
            top: -size.height * 0.2,
            child: Container(
              // --- UKURAN DIPERBESAR SECARA SIGNIFIKAN ---
              height: size.height * 1.2,
              width: size.width * 2.0,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    // --- OPASITAS DITINGKATKAN LAGI ---
                    Color(0x88A9FF58), // Dari 0x77 menjadi 0x88
                    Color.fromARGB(0, 119, 107, 255),
                  ],
                ),
              ),
            ),
          ),

          // Lapisan Blur untuk membaurkan
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(color: const Color.fromARGB(0, 128, 0, 255)),
            ),
          ),
          
          // Konten Aplikasi Anda
          child,
        ],
      ),
    );
  }
}