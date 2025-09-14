import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter/material.dart'; // <-- Pastikan tidak ada titik setelah 'package'
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- Pastikan tidak ada titik setelah 'package'

class AddEditTemplatePage extends ConsumerStatefulWidget {
  final TaskTemplate? template;

  const AddEditTemplatePage({super.key, this.template});

  @override
  ConsumerState<AddEditTemplatePage> createState() => _AddEditTemplatePageState();
}

class _AddEditTemplatePageState extends ConsumerState<AddEditTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<TemplateTaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _tasks = widget.template?.tasks.map((task) => task).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate() && _tasks.isNotEmpty) {
      final firestoreService = ref.read(firestoreServiceProvider);

      final newOrUpdatedTemplate = TaskTemplate(
        id: widget.template?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        tasks: _tasks,
      );

      if (widget.template == null) {
        firestoreService.addTaskTemplate(newOrUpdatedTemplate);
      } else {
        firestoreService.updateTaskTemplate(newOrUpdatedTemplate);
      }

      Navigator.of(context).pop();
    } else if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template harus memiliki setidaknya satu tugas.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showTaskDialog({TemplateTaskItem? task, int? index}) {
    final taskNameController = TextEditingController(text: task?.name ?? '');
    TaskCategory selectedCategory = task?.category ?? TaskCategory.OneTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'Tambah Tugas' : 'Edit Tugas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskNameController,
                    decoration: const InputDecoration(labelText: 'Nama Tugas'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskCategory>(
                    value: selectedCategory,
                    items: TaskCategory.values.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat.name));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (taskNameController.text.isNotEmpty) {
                      final newTask = TemplateTaskItem(
                        name: taskNameController.text.trim(),
                        category: selectedCategory,
                      );
                      setState(() {
                        if (index != null) {
                          _tasks[index] = newTask;
                        } else {
                          _tasks.add(newTask);
                        }
                      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Buat Template Baru' : 'Edit Template'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveTemplate)],
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
                decoration: const InputDecoration(labelText: 'Nama Template'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tugas', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _showTaskDialog(),
                  ),
                ],
              ),
              const Divider(),
              if (_tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Belum ada tugas. Klik + untuk menambah.')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return ListTile(
                      title: Text(task.name),
                      subtitle: Text(task.category.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() => _tasks.removeAt(index));
                        },
                      ),
                      onTap: () => _showTaskDialog(task: task, index: index),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}