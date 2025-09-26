import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/app_background.dart'; // <-- IMPORT BARU
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airdrop_flow/core/widgets/custom_form_dialog.dart';

class SocialManagementPage extends ConsumerWidget {
  const SocialManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialsAsyncValue = ref.watch(socialAccountsStreamProvider);

    return AppBackground( // <-- WIDGET DITAMBAHKAN
      child: Scaffold(
        backgroundColor: Colors.transparent, // <-- MODIFIKASI
        appBar: AppBar(
          title: const Text('Manajemen Akun Sosial'),
          backgroundColor: Colors.transparent, // <-- Tambahan
          elevation: 0, // <-- Tambahan
        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Akun "${account.username}" dihapus.',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red.shade700,
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
          onPressed: () => _showAddSocialDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.twitter:
        return Icons.flutter_dash;
      case SocialPlatform.discord:
        return Icons.discord;
      case SocialPlatform.telegram:
        return Icons.send;
    }
  }

  void _showAddSocialDialog(BuildContext context, WidgetRef ref) async {
    final usernameController = TextEditingController();
    var selectedPlatform = SocialPlatform.twitter;

    final bool? didSave = await showCustomFormDialog(
      context: context,
      title: 'Tambah Akun Sosial',
      children: [
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DropdownButtonFormField<SocialPlatform>(
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
              decoration: const InputDecoration(labelText: 'Platform'),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username tidak boleh kosong.';
            }
            return null;
          },
        ),
      ],
      onSave: () {
        final newAccount = SocialAccount(
          id: '',
          platform: selectedPlatform,
          username: usernameController.text.trim(),
        );
        ref.read(firestoreServiceProvider).addSocialAccount(newAccount);
      },
    );

    if (didSave == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun "${usernameController.text.trim()}" berhasil ditambahkan!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}