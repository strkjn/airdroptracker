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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      // Efek blur (kaca) dikembalikan sebagai fokus utama
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            // --- KEMBALI KE EFEK KACA MURNI ---
            // Gradasi warna dihilangkan
            color: Colors.white.withOpacity(0.1), // Warna kaca semi-transparan
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}