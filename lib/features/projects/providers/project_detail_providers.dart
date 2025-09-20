// lib/features/projects/providers/project_detail_providers.dart

import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kelas sederhana untuk menampung data gabungan dari wallet dan akun sosial.
class ProjectAssociatedData {
  final List<Wallet> wallets;
  final List<SocialAccount> socialAccounts;

  ProjectAssociatedData({
    required this.wallets,
    required this.socialAccounts,
  });
}

/// --- PERUBAHAN UTAMA DI SINI ---
/// Provider yang menggabungkan status AsyncValue dari wallets dan social accounts.
///
/// Pola ini lebih tangguh daripada menggunakan RxDart's CombineLatestStream secara langsung
/// di dalam provider karena dapat menangani state loading dan error dari
/// masing-masing stream sumber secara eksplisit.
final projectAssociatedDataProvider = Provider.autoDispose<AsyncValue<ProjectAssociatedData>>((ref) {
  final walletsAsync = ref.watch(walletsStreamProvider);
  final socialsAsync = ref.watch(socialAccountsStreamProvider);

  // Jika salah satu stream sumber mengalami error, kembalikan state error tersebut.
  if (walletsAsync.hasError) {
    return AsyncValue.error(walletsAsync.error!, walletsAsync.stackTrace!);
  }
  if (socialsAsync.hasError) {
    return AsyncValue.error(socialsAsync.error!, socialsAsync.stackTrace!);
  }

  // Jika salah satu stream sumber masih loading, kembalikan state loading.
  if (walletsAsync.isLoading || socialsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Jika kedua stream sumber sudah memiliki data, gabungkan dan kembalikan.
  return AsyncValue.data(ProjectAssociatedData(
    wallets: walletsAsync.value!,
    socialAccounts: socialsAsync.value!,
  ));
});