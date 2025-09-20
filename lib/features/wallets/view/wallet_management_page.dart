// lib/features/wallets/view/wallet_management_page.dart

import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORT BARU ---
import 'package:airdrop_flow/core/widgets/custom_form_dialog.dart';

class WalletManagementPage extends ConsumerWidget {
  const WalletManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsyncValue = ref.watch(walletsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Wallet')),
      body: walletsAsyncValue.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(
              child: Text('Belum ada wallet yang ditambahkan.'),
            );
          }
          return ListView.builder(
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return ListTile(
                title: Text(wallet.walletName),
                subtitle: Text(wallet.publicAddress),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () {
                    // Logika hapus tidak berubah dan tetap aman
                    ref.read(firestoreServiceProvider).deleteWallet(wallet.id);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- FUNGSI DIALOG YANG DIPERBARUI & LEBIH SEDERHANA ---
  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    // Menggunakan widget dialog kustom yang baru
    showCustomFormDialog(
      context: context,
      title: 'Tambah Wallet Baru',
      // 'children' diisi dengan field input yang kita butuhkan
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Wallet (e.g. Metamask Utama)',
          ),
          // Tambahkan validasi agar nama tidak boleh kosong
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama wallet tidak boleh kosong.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Alamat Publik (0x...)',
          ),
        ),
      ],
      // Logika 'onSave' tetap sama, hanya dipindahkan ke sini
      onSave: () {
        final newWallet = Wallet(
          id: '',
          walletName: nameController.text.trim(),
          publicAddress: addressController.text.trim(),
        );
        ref.read(firestoreServiceProvider).addWallet(newWallet);
      },
    );
  }
}