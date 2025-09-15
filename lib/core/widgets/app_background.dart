import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Stack untuk menumpuk beberapa lapisan
    return Stack(
      children: [
        // Lapisan 1: Warna dasar hitam pekat
        Container(color: Colors.black),

        // Lapisan 2: Gradasi ungu dari pojok kanan bawah
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomRight,
              radius: 0.9,
              colors: [
                Color(0xFF4a2e6f), // Warna ungu
                Colors.transparent,
              ],
              stops: [0.0, 0.8],
            ),
          ),
        ),

        // Lapisan 3: Gradasi biru dari atas
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2, // Radius lebih besar agar lebih menyebar & lembut
              colors: [
                Color(0xFF16213e), // Warna biru tua sebagai aksen atas
                Colors.transparent,
              ],
              stops: [0.0, 0.7], // Memudar sedikit lebih cepat
            ),
          ),
        ),

        // Lapisan 4: Konten utama aplikasi Anda
        // Ditampilkan di atas semua lapisan latar belakang
        child,
      ],
    );
  }
}