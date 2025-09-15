import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  // Properti 'glowColor' kita hapus dari sini
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
            // Kita gunakan warna solid semi-transparan untuk efek kaca netral
            color: Colors.white.withAlpha(25), // setara dengan opacity 0.1
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withAlpha(51), // setara dengan opacity 0.2
              width: 1.0,
            ),
            // Efek boxShadow dan glowColor dihapus dari sini
          ),
          child: child,
        ),
      ),
    );
  }
}