import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get canUseBiometrics async {
    return await _auth.canCheckBiometrics;
  }
  
  Future<bool> authenticate({required String reason}) async {
    try {
      // FIX: Jika tidak ada sensor, kembalikan false karena autentikasi tidak bisa dilakukan.
      if (!await canUseBiometrics) {
        return false;
      }
      
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error otentikasi: $e');
      return false;
    }
  }
}