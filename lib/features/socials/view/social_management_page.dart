import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialManagementPage extends ConsumerWidget {
  const SocialManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialsAsyncValue = ref.watch(socialAccountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Akun Sosial')),
      body: socialsAsyncValue.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text('Belum ada akun sosial yang ditambahkan.'),
            );
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: Icon(_getPlatformIcon(account.platform)),
                title: Text(account.username),
                subtitle: Text(account.platform.name),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () {
                    ref
                        .read(firestoreServiceProvider)
                        .deleteSocialAccount(account.id);
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
        onPressed: () => _showAddSocialDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.Twitter:
        return Icons.flutter_dash;
      case SocialPlatform.Discord:
        return Icons.discord;
      case SocialPlatform.Telegram:
        return Icons.send;
    }
  }

  void _showAddSocialDialog(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    SocialPlatform selectedPlatform = SocialPlatform.Twitter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Akun Sosial'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<SocialPlatform>(
                    value: selectedPlatform,
                    isExpanded: true,
                    items: SocialPlatform.values.map((platform) {
                      return DropdownMenuItem(
                        value: platform,
                        child: Text(platform.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPlatform = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
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
                    if (usernameController.text.isNotEmpty) {
                      final newAccount = SocialAccount(
                        id: '',
                        platform: selectedPlatform,
                        username: usernameController.text.trim(),
                      );
                      ref
                          .read(firestoreServiceProvider)
                          .addSocialAccount(newAccount);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
