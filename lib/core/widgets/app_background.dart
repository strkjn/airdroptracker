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
          // Pendaran cahaya UNGU dari KIRI ATAS (tidak berubah)
          Positioned(
            left: -size.width * 0.7,
            top: -size.height * 0.6,
            child: Container(
              height: size.height * 1,
              width: size.width * 1,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color.fromARGB(153, 106, 26, 255),
                    Color.fromARGB(0, 118, 103, 255),
                  ],
                ),
              ),
            ),
          ),
          
          // --- PERUBAHAN DI SINI ---
          // Pendaran cahaya KANAN TENGAH
          Positioned(
            right: -size.width * 0.8,
            // 1. Posisi diturunkan sedikit (nilai top mendekati 0)
            top: -size.height * 0.1, 
            child: Container(
              height: size.height * 1,
              width: size.width * 1,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    // 2. Warna diubah dari hijau menjadi nuansa ungu yang berbeda
                    Color.fromARGB(136, 173, 58, 255), 
                    Color.fromARGB(0, 119, 107, 255),
                  ],
                ),
              ),
            ),
          ),

          // Lapisan Blur untuk membaurkan (tidak berubah)
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