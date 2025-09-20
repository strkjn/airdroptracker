// lib/core/widgets/custom_form_dialog.dart

import 'package:flutter/material.dart';

/// --- PERUBAHAN UTAMA: MENGUBAH RETURN TYPE MENJADI Future<bool?> ---
/// Mengembalikan `true` jika disimpan, `false` atau `null` jika dibatalkan.
Future<bool?> showCustomFormDialog({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required VoidCallback onSave,
  String saveButtonText = 'Simpan',
}) {
  final formKey = GlobalKey<FormState>();

  return showDialog<bool>( // <-- Mengubah tipe generik menjadi <bool>
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
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
              // --- PERUBAHAN: Mengembalikan false saat dibatalkan ---
              Navigator.of(context).pop(false);
            },
          ),
          ElevatedButton(
            child: Text(saveButtonText),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                onSave();
                // --- PERUBAHAN: Mengembalikan true saat disimpan ---
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      );
    },
  );
}