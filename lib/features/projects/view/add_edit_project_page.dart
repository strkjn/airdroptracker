// lib/features/projects/view/add_edit_project_page.dart

import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditProjectPage extends ConsumerStatefulWidget {
  final Project? project;

  const AddEditProjectPage({super.key, this.project});

  @override
  ConsumerState<AddEditProjectPage> createState() => _AddEditProjectPageState();
}

class _AddEditProjectPageState extends ConsumerState<AddEditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _websiteController;
  late TextEditingController _notesController;
  late ProjectStatus _selectedStatus;

  // --- PERUBAHAN: Menggunakan TextEditingController untuk jaringan ---
  late TextEditingController _networkController;

  // --- BARU: State untuk menyimpan ID wallet & akun sosial yang dipilih ---
  Set<String> _selectedWalletIds = {};
  Set<String> _selectedSocialAccountIds = {};

  @override
  void initState() {
    super.initState();
    final project = widget.project;

    _nameController = TextEditingController(text: project?.name ?? '');
    _websiteController = TextEditingController(text: project?.websiteUrl ?? '');
    _notesController = TextEditingController(text: project?.notes ?? '');
    _selectedStatus = project?.status ?? ProjectStatus.active;
    _networkController = TextEditingController(text: project?.blockchainNetwork ?? '');

    if (project != null) {
      _selectedWalletIds = project.associatedWalletIds.toSet();
      _selectedSocialAccountIds = project.associatedSocialAccountIds.toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final firestoreService = ref.read(firestoreServiceProvider);
      final isEditing = widget.project != null;

      final projectData = Project(
        id: isEditing ? widget.project!.id : '',
        name: _nameController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        notes: _notesController.text.trim(),
        status: _selectedStatus,
        blockchainNetwork: _networkController.text.trim(),
        // --- BARU: Menyimpan daftar ID yang dipilih ---
        associatedWalletIds: _selectedWalletIds.toList(),
        associatedSocialAccountIds: _selectedSocialAccountIds.toList(),
      );

      if (isEditing) {
        firestoreService.updateProject(projectData);
      } else {
        firestoreService.addProject(projectData);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Tambah Proyek Baru' : 'Edit Proyek'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _submitForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Input Fields Dasar ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Proyek'),
                validator: (value) => (value == null || value.isEmpty) ? 'Nama proyek tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'URL Website (Opsional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ProjectStatus.values.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 16),
              
              // --- PERUBAHAN: Input teks untuk Jaringan Blockchain ---
              TextFormField(
                controller: _networkController,
                decoration: const InputDecoration(labelText: 'Jaringan Blockchain (misal: Ethereum, Solana)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan & Strategi (Opsional)', alignLabelWithHint: true),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const Divider(height: 32),

              // --- BAGIAN BARU: Pilih Wallet ---
              Text('Tautkan Wallet', style: Theme.of(context).textTheme.titleMedium),
              _buildWalletsSelector(),
              const SizedBox(height: 16),

              // --- BAGIAN BARU: Pilih Akun Sosial ---
              Text('Tautkan Akun Sosial', style: Theme.of(context).textTheme.titleMedium),
              _buildSocialsSelector(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk membangun daftar checkbox wallet
  Widget _buildWalletsSelector() {
    final walletsAsync = ref.watch(walletsStreamProvider);
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) return const Text('Tidak ada wallet. Tambahkan di halaman Pengaturan.');
        return Column(
          children: wallets.map((wallet) {
            return CheckboxListTile(
              title: Text(wallet.walletName),
              subtitle: Text(wallet.publicAddress, overflow: TextOverflow.ellipsis),
              value: _selectedWalletIds.contains(wallet.id),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedWalletIds.add(wallet.id);
                  } else {
                    _selectedWalletIds.remove(wallet.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Text('Gagal memuat wallet'),
    );
  }

  // Widget untuk membangun daftar checkbox akun sosial
  Widget _buildSocialsSelector() {
    final socialsAsync = ref.watch(socialAccountsStreamProvider);
    return socialsAsync.when(
      data: (socials) {
        if (socials.isEmpty) return const Text('Tidak ada akun sosial. Tambahkan di halaman Pengaturan.');
        return Column(
          children: socials.map((account) {
            return CheckboxListTile(
              title: Text(account.username),
              subtitle: Text(account.platform.name),
              value: _selectedSocialAccountIds.contains(account.id),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedSocialAccountIds.add(account.id);
                  } else {
                    _selectedSocialAccountIds.remove(account.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Text('Gagal memuat akun sosial'),
    );
  }
}