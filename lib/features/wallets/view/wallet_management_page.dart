// lib/features/wallets/view/wallet_management_page.dart

import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    ref.read(firestoreServiceProvider).deleteWallet(wallet.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Wallet "${wallet.walletName}" dihapus.',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red.shade700,
                        // --- PERBAIKAN DI SINI ---
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final bool? didSave = await showCustomFormDialog(
      context: context,
      title: 'Tambah Wallet Baru',
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Wallet (e.g. Metamask Utama)',
          ),
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
      onSave: () {
        final newWallet = Wallet(
          id: '',
          walletName: nameController.text.trim(),
          publicAddress: addressController.text.trim(),
        );
        ref.read(firestoreServiceProvider).addWallet(newWallet);
      },
    );

    if (didSave == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wallet "${nameController.text.trim()}" berhasil ditambahkan!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          // --- PERBAIKAN DI SINI ---
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}