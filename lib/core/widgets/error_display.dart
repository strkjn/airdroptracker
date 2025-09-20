// lib/core/widgets/error_display.dart

import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorDisplay({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded, // Ikon yang lebih relevan
              color: Colors.white.withOpacity(0.6),
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Terjadi Kesalahan',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // Menampilkan pesan error yang lebih bersih
              errorMessage.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                // Menggunakan warna sekunder tema agar sedikit berbeda
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}