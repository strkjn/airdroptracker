// lib/features/projects/providers/project_detail_providers.dart

import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

/// Kelas sederhana untuk menampung data gabungan dari wallet dan akun sosial.
class ProjectAssociatedData {
  final List<Wallet> wallets;
  final List<SocialAccount> socialAccounts;

  ProjectAssociatedData({
    required this.wallets,
    required this.socialAccounts,
  });
}

/// Provider yang menggabungkan stream dari wallets dan social accounts.
///
/// Menggunakan RxDart `CombineLatestStream`, provider ini akan memancarkan
/// sebuah objek [ProjectAssociatedData] baru setiap kali salah satu dari
/// stream sumber (wallets atau social accounts) memancarkan data baru.
/// Ini menyederhanakan widget UI karena hanya perlu memantau satu stream.
final projectAssociatedDataProvider = StreamProvider<ProjectAssociatedData>((ref) {
  final walletsStream = ref.watch(walletsStreamProvider.stream);
  final socialAccountsStream = ref.watch(socialAccountsStreamProvider.stream);

  return CombineLatestStream.combine2(
    walletsStream,
    socialAccountsStream,
    (List<Wallet> wallets, List<SocialAccount> socialAccounts) {
      return ProjectAssociatedData(
        wallets: wallets,
        socialAccounts: socialAccounts,
      );
    },
  );
});