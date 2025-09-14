import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Wallet Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Wallet (e.g. Metamask Utama)',
              ),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Publik (0x...)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newWallet = Wallet(
                  id: '',
                  walletName: nameController.text.trim(),
                  publicAddress: addressController.text.trim(),
                );

                ref.read(firestoreServiceProvider).addWallet(newWallet);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
