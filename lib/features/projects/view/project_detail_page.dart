import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/projects/providers/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectDetailPage extends ConsumerWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsyncValue = ref.watch(processedTasksProvider(project.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          // Tombol untuk menerapkan template
          IconButton(
            icon: const Icon(Icons.library_add_check_outlined),
            onPressed: () => _showApplyTemplateDialog(context, ref, project.id),
            tooltip: 'Terapkan Template',
          ),
        ],
      ),
      body: tasksAsyncValue.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada tugas di proyek ini.\nKlik tombol + untuk menambah tugas manual,\natau tombol di kanan atas untuk menerapkan template.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Beri ruang untuk FAB
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref
                      .read(firestoreServiceProvider)
                      .deleteTask(projectId: project.id, taskId: task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tugas "${task.name}" dihapus')),
                  );
                },
                background: Container(
                  color: Colors.red.shade700,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_sweep, color: Colors.white),
                ),
                child: TaskTile(task: task),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref, project.id),
        child: const Icon(Icons.add_task),
        tooltip: 'Tambah Tugas Manual',
      ),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref, String projectId) {
    final templatesAsync = ref.watch(taskTemplatesStreamProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terapkan Template Tugas'),
          content: SizedBox(
            width: double.maxFinite,
            child: templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const Text('Anda belum memiliki template. Buat satu di halaman Pengaturan.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return ListTile(
                      title: Text(template.name),
                      subtitle: Text('${template.tasks.length} tugas'),
                      onTap: () async {
                        await ref
                            .read(firestoreServiceProvider)
                            .applyTemplateToProject(projectId: projectId, template: template);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Template "${template.name}" berhasil diterapkan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Gagal memuat template.'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref, String projectId) {
    final nameController = TextEditingController();
    TaskCategory selectedCategory = TaskCategory.OneTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Tugas Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Tugas'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskCategory>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: TaskCategory.values.map((TaskCategory category) {
                      return DropdownMenuItem<TaskCategory>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => selectedCategory = newValue);
                      }
                    },
                     decoration: const InputDecoration(labelText: 'Kategori'),
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
                      ref.read(firestoreServiceProvider).addTaskToProject(
                            projectId: projectId,
                            taskName: nameController.text.trim(),
                            category: selectedCategory,
                          );
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

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: Text(task.category.name),
      value: task.isCompleted,
      onChanged: (newValue) {
        ref.read(firestoreServiceProvider).updateTaskStatus(
              projectId: task.projectId,
              taskId: task.id,
              isCompleted: newValue!,
            );
      },
    );
  }
}