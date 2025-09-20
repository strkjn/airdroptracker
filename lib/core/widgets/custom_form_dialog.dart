// lib/core/widgets/custom_form_dialog.dart

import 'package:flutter/material.dart';

/// Sebuah widget dialog kustom yang dapat digunakan kembali untuk menampilkan formulir.
///
/// Widget ini menyediakan struktur dasar AlertDialog dengan judul,
/// konten yang dapat digulir, serta tombol 'Batal' dan 'Simpan'.
Future<void> showCustomFormDialog({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required VoidCallback onSave,
  String saveButtonText = 'Simpan',
}) {
  // GlobalKey ini penting untuk memvalidasi form di dalam dialog.
  final formKey = GlobalKey<FormState>();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        // Menggunakan SingleChildScrollView agar tidak error jika kontennya panjang
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: ListBody(
              children: children,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text(saveButtonText),
            onPressed: () {
              // Validasi form sebelum menyimpan
              if (formKey.currentState?.validate() ?? false) {
                onSave();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}