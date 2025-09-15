import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dekorasi untuk membuat latar belakang gradasi
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center, // Pusat gradasi di tengah layar
          radius: 1.2, // Radius gradasi, >1.0 agar warna terluar lebih dominan di sudut
          colors: [
            Color(0xFF1a1a2e), // Warna tengah yang lebih gelap (biru kehitaman)
            Color(0xFF16213e), // Warna transisi
            Color(0xFF4a2e6f), // Warna ungu gelap di bagian luar
          ],
          stops: [
            0.0, // Posisi awal warna tengah
            0.5, // Posisi transisi
            1.0, // Posisi akhir warna ungu
          ],
        ),
      ),
      // Kita tidak perlu Scaffold di sini, langsung tampilkan konten `child`
      child: child,
    );
  }
}