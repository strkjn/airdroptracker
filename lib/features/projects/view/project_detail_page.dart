// lib/features/projects/view/project_detail_page.dart

import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/projects/providers/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      return task.lastCompletedTimestamp != null &&
          isSameDay(task.lastCompletedTimestamp, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsyncValue = ref.watch(processedTasksProvider(widget.project.id));
    final completedTasksOnSelectedDay = tasksAsyncValue.whenData(
      (allTasks) => _getTasksForDay(_selectedDay!, allTasks)
    ).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_check_outlined),
            onPressed: () => _showApplyTemplateDialog(context, ref, widget.project.id),
            tooltip: 'Terapkan Template',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar<Task>(
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) {
                return tasksAsyncValue.whenData(
                  (allTasks) => _getTasksForDay(day, allTasks)
                ).value ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        width: 7,
                        height: 7,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const Divider(),
            if (completedTasksOnSelectedDay.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada aktivitas pada ${DateFormat.yMMMMd().format(_selectedDay!)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Aktivitas pada ${DateFormat.yMMMMd().format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...completedTasksOnSelectedDay.map((task) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(task.name),
                        subtitle: Text('Selesai pada ${DateFormat.Hm().format(task.lastCompletedTimestamp!)}'),
                      )),
                ],
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Semua Tugas Proyek', style: Theme.of(context).textTheme.titleLarge),
            ),
            tasksAsyncValue.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada tugas di proyek ini.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref.read(firestoreServiceProvider).deleteTask(projectId: widget.project.id, taskId: task.id);
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
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(child: Text('Gagal memuat tugas: $err')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref, widget.project.id),
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
                if (templates.isEmpty) return const Text('Anda belum memiliki template.');
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return ListTile(
                      title: Text(template.name),
                      subtitle: Text('${template.tasks.length} tugas'),
                      onTap: () async {
                        await ref.read(firestoreServiceProvider).applyTemplateToProject(projectId: projectId, template: template);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Template "${template.name}" berhasil diterapkan!'), backgroundColor: Colors.green),
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
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal'))],
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
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Tugas')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskCategory>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: TaskCategory.values.map((TaskCategory category) {
                      return DropdownMenuItem<TaskCategory>(value: category, child: Text(category.name));
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) setState(() => selectedCategory = newValue);
                    },
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
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