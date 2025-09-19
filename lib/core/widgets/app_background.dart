// lib/core/widgets/app_background.dart

import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Cukup kembalikan sebuah Container berwarna hitam yang membungkus child.
    // Ini memastikan konsistensi jika ada Scaffold yang tidak menggunakan tema.
    return Container(
      color: Colors.black,
      child: child,
    );
  }
}