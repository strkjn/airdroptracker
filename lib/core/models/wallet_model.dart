import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String walletName;
  final String publicAddress;

  Wallet({required this.id, required this.walletName, this.publicAddress = ''});

  factory Wallet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Wallet(
      id: snapshot.id,
      walletName: data['walletName'] ?? '',
      publicAddress: data['publicAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'walletName': walletName, 'publicAddress': publicAddress};
  }
}
