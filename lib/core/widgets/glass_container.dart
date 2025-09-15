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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(borderRadius),
            // --- BARIS KODE BARU DITAMBAHKAN DI SINI ---
            border: Border.all(
              color: Colors.white.withAlpha(51), // Border putih lembut
              width: 1.0, // Ketebalan border
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}