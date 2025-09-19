// lib/core/widgets/glass_container.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.margin,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Hanya menggunakan Container dengan Decoration, tanpa blur.
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        // --- IMPLEMENTASI GRADASI SESUAI REFERENSI ---
        gradient: RadialGradient(
          colors: [
            // Warna terang sebagai pusat cahaya
            primaryColor.withOpacity(0.35),

            // Warna dasar kartu yang gelap dan pekat
            const Color(0xFF1A1A1C), 
          ],
          // Pusat cahaya di sudut kanan atas
          center: const Alignment(1.0, -1.0),
          
          // Radius diatur agar transisi terasa lembut dan menyebar
          radius: 1.5,

          // Mengatur transisi agar warna terang lebih fokus di sudut
          stops: const [0.0, 0.9],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}