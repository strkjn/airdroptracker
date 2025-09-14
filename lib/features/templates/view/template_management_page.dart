import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/templates/view/add_edit_template_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateManagementPage extends ConsumerWidget {
  const TemplateManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(taskTemplatesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Template')),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada template.\nKlik tombol + di bawah untuk membuat template pertama Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.name),
                subtitle: Text(template.description.isNotEmpty 
                  ? template.description 
                  : '${template.tasks.length} tugas'),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _confirmDelete(context, ref, template),
                ),
                onTap: () {
                  // Navigasi ke halaman edit dengan membawa data template
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTemplatePage(template: template),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah (tanpa membawa data template)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTemplatePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Buat Template Baru',
      ),
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menghapus
  void _confirmDelete(BuildContext context, WidgetRef ref, TaskTemplate template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus template "${template.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () {
                ref.read(firestoreServiceProvider).deleteTaskTemplate(template.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template "${template.name}" dihapus'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        );
      },
    );
  }
}