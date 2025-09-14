import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Fungsi untuk memeriksa apakah perangkat memiliki sensor biometrik
  Future<bool> get canUseBiometrics async {
    return await _auth.canCheckBiometrics;
  }
  
  // Fungsi utama untuk memulai proses otentikasi
  Future<bool> authenticate({required String reason}) async {
    try {
      if (!await canUseBiometrics) {
        // Jika tidak ada sensor, anggap saja berhasil (tidak ada keamanan)
        return true;
      }
      
      // Menampilkan dialog otentikasi (sidik jari/Face ID)
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Tetap di layar sampai berhasil/gagal
          biometricOnly: true, // Hanya izinkan biometrik (bukan PIN perangkat)
        ),
      );
    } on PlatformException catch (e) {
      print('Error otentikasi: $e');
      return false; // Gagal otentikasi
    }
  }
}