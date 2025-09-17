import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get canUseBiometrics async {
    try {
      // Memeriksa apakah perangkat memiliki dukungan hardware untuk biometrik
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      // Jika ada error saat memeriksa, anggap tidak bisa
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      // Kita akan mengizinkan fallback ke PIN/Pola dengan menghapus 'biometricOnly: true'
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Biarkan prompt tetap muncul
          // biometricOnly: true, // <-- BARIS INI DIHAPUS/DIKOMENTARI
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}