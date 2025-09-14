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
  late BlockchainNetwork _selectedNetwork;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _websiteController = TextEditingController(
      text: widget.project?.websiteUrl ?? '',
    );
    _notesController = TextEditingController(text: widget.project?.notes ?? '');
    _selectedStatus = widget.project?.status ?? ProjectStatus.active;
    _selectedNetwork =
        widget.project?.blockchainNetwork ?? BlockchainNetwork.ethereum;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final firestoreService = ref.read(firestoreServiceProvider);

      if (widget.project == null) {
        final newProject = Project(
          id: '',
          name: _nameController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          notes: _notesController.text.trim(),
          status: _selectedStatus,
          blockchainNetwork: _selectedNetwork,
        );
        firestoreService.addProject(newProject);
      } else {
        final updatedProject = Project(
          id: widget.project!.id,
          name: _nameController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          notes: _notesController.text.trim(),
          status: _selectedStatus,
          blockchainNetwork: _selectedNetwork,

          associatedWalletIds: widget.project!.associatedWalletIds,
          associatedSocialAccountIds:
              widget.project!.associatedSocialAccountIds,
        );
        firestoreService.updateProject(updatedProject);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project == null ? 'Tambah Proyek Baru' : 'Edit Proyek',
        ),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Proyek'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama proyek tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'URL Website (Opsional)',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ProjectStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.name[0].toUpperCase() + status.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BlockchainNetwork>(
                value: _selectedNetwork,
                decoration: const InputDecoration(
                  labelText: 'Jaringan Blockchain',
                ),
                items: BlockchainNetwork.values.map((network) {
                  return DropdownMenuItem(
                    value: network,
                    child: Text(
                      network.name[0].toUpperCase() + network.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedNetwork = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan & Strategi (Opsional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
