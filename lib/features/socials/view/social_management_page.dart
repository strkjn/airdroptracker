// lib/features/socials/view/social_management_page.dart

import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORT BARU ---
import 'package:airdrop_flow/core/widgets/custom_form_dialog.dart';

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
      case SocialPlatform.twitter:
        return Icons.flutter_dash; // Placeholder, bisa diganti ikon Twitter
      case SocialPlatform.discord:
        return Icons.discord;
      case SocialPlatform.telegram:
        return Icons.send;
    }
  }

  // --- FUNGSI DIALOG YANG DIPERBARUI & LEBIH SEDERHANA ---
  void _showAddSocialDialog(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    // Variabel untuk menyimpan state dropdown
    var selectedPlatform = SocialPlatform.twitter;

    showCustomFormDialog(
      context: context,
      title: 'Tambah Akun Sosial',
      // 'children' diisi dengan widget yang kita butuhkan
      children: [
        // StatefulBuilder diperlukan agar dropdown bisa diperbarui di dalam dialog
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
      // Logika 'onSave' tetap sama
      onSave: () {
        final newAccount = SocialAccount(
          id: '',
          platform: selectedPlatform,
          username: usernameController.text.trim(),
        );
        ref.read(firestoreServiceProvider).addSocialAccount(newAccount);
      },
    );
  }
}