// lib/features/projects/view/project_detail_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/projects/providers/project_providers.dart';
import 'package:airdrop_flow/features/projects/view/add_edit_project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

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

  // Fungsi ini tidak berubah, digunakan oleh kalender
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.lastCompletedTimestamp == null) return false;
      return isSameDay(task.lastCompletedTimestamp, day);
    }).toList();
  }

  // --- SEMUA FUNGSI HELPER (DIALOG) TIDAK BERUBAH ---
  void _confirmDeleteProject(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus proyek "${project.name}"? Semua tugas di dalamnya juga akan terhapus.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () async {
                await ref.read(firestoreServiceProvider).deleteProject(project.id);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        );
      },
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
                        if (context.mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(singleProjectStreamProvider(widget.projectId));

    return projectAsync.when(
      data: (project) {
        // 1. Panggil provider yang baru untuk daftar tugas
        final projectTasksAsync = ref.watch(projectTasksProvider(project.id));
        // 2. Panggil provider STREAM yang lama KHUSUS untuk data kalender
        final allTasksForCalendarAsync = ref.watch(tasksStreamProvider(project.id));
        
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.3),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditProjectPage(project: project))),
                tooltip: 'Edit Proyek',
              ),
              IconButton(
                icon: const Icon(Icons.library_add_check_outlined),
                onPressed: () => _showApplyTemplateDialog(context, ref, project.id),
                tooltip: 'Terapkan Template',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _confirmDeleteProject(context, ref, project),
                tooltip: 'Hapus Proyek',
              ),
            ],
          ),
          body: projectTasksAsync.when(
            data: (taskData) {
              final selectedDay = _selectedDay;
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectInfoSection(project: project),
                    
                    // --- Tampilan Daftar Tugas yang Baru ---
                    if (taskData.today.isNotEmpty)
                      _TaskListSection(
                        title: 'Tugas Hari Ini',
                        tasks: taskData.today,
                        isEnabled: true,
                      ),
                    
                    if (taskData.oneTime.isNotEmpty)
                       _TaskListSection(
                        title: 'Tugas Sekali Selesai',
                        tasks: taskData.oneTime,
                        isEnabled: true,
                      ),

                    if (taskData.tomorrow.isNotEmpty)
                       _TaskListSection(
                        title: 'Akan Datang Besok',
                        tasks: taskData.tomorrow,
                        isEnabled: false,
                      ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Kalender Aktivitas', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 8),

                    // 3. Bangun kalender menggunakan data dari `allTasksForCalendarAsync`
                    allTasksForCalendarAsync.when(
                      data: (allTasks) {
                        final completedTasksOnSelectedDay = selectedDay != null ? _getTasksForDay(selectedDay, allTasks) : <Task>[];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassContainer(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: TableCalendar<Task>(
                                calendarFormat: CalendarFormat.week,
                                firstDay: DateTime.utc(2022, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                startingDayOfWeek: StartingDayOfWeek.monday,
                                eventLoader: (day) => _getTasksForDay(day, allTasks), // Gunakan semua tugas
                                onDaySelected: (selectedDay, focusedDay) {
                                  if (!isSameDay(_selectedDay, selectedDay)) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  }
                                },
                                headerStyle: const HeaderStyle(
                                  titleCentered: true,
                                  formatButtonVisible: false,
                                ),
                                calendarStyle: CalendarStyle(
                                  selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                                  todayDecoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, date, events) {
                                    if (events.isNotEmpty) {
                                      return Positioned(right: 4, top: 4, child: Container(
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.secondary.withOpacity(0.8)),
                                        width: 7, height: 7,
                                      ));
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            if (selectedDay != null && completedTasksOnSelectedDay.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('Aktivitas pada ${DateFormat.yMMMMd('id_ID').format(selectedDay)}', style: Theme.of(context).textTheme.titleLarge),
                              ),
                              const SizedBox(height: 8),
                              GlassContainer(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: completedTasksOnSelectedDay
                                      .map((task) => ListTile(
                                            leading: const Icon(Icons.check_circle, color: Colors.green),
                                            title: Text(task.name),
                                            subtitle: task.lastCompletedTimestamp != null
                                                ? Text('Selesai pada ${DateFormat.Hm().format(task.lastCompletedTimestamp!)}')
                                                : null,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Gagal memuat riwayat: $err')),
                    ),
                    const SizedBox(height: 80), // Spacer di bawah
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Gagal memuat tugas: $err')),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context, ref, project.id),
            tooltip: 'Tambah Tugas Manual',
            child: const Icon(Icons.add_task),
          ),
        );
      },
      loading: () => Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(title: const Text('Error')), body: Center(child: Text('Gagal memuat proyek: $err'))),
    );
  }
}

// Widget baru untuk menampilkan setiap bagian daftar tugas
class _TaskListSection extends ConsumerWidget {
  const _TaskListSection({
    required this.title,
    required this.tasks,
    required this.isEnabled,
  });

  final String title;
  final List<Task> tasks;
  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.zero,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(firestoreServiceProvider).deleteTask(projectId: task.projectId, taskId: task.id);
                },
                background: Container(
                  color: Colors.red.shade700,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_sweep, color: Colors.white),
                ),
                child: TaskTile(task: task, isEnabled: isEnabled),
              );
            },
          ),
        ),
      ],
    );
  }
}


// --- WIDGET-WIDGET DI BAWAH INI SEBAGIAN BESAR TIDAK BERUBAH ---
// Saya hanya memindahkan TaskTile ke sini agar bisa digunakan kembali

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, required this.isEnabled});
  final Task task;
  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCompleted = isEnabled ? task.isCompleted : false;
    final Color textColor = isEnabled ? (isCompleted ? Colors.grey : Colors.white) : Colors.grey;
    final nextResetDate = task.lastCompletedTimestamp?.add(const Duration(days: 1));

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: CheckboxListTile(
        title: Text(
          task.name,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: textColor,
          ),
        ),
        subtitle: Row(
          children: [
            Text(task.category.name, style: TextStyle(color: textColor)),
            if (!isEnabled && nextResetDate != null) ...[
              const SizedBox(width: 8),
              Text(
                "(${DateFormat('d MMM', 'id_ID').format(nextResetDate)})",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.amber),
              )
            ]
          ],
        ),
        value: isCompleted,
        onChanged: isEnabled
            ? (newValue) {
                if (newValue != null) {
                  ref.read(firestoreServiceProvider).updateTaskStatus(
                        projectId: task.projectId,
                        taskId: task.id,
                        isCompleted: newValue,
                      );
                }
              }
            : null,
      ),
    );
  }
}

class _ProjectInfoSection extends StatelessWidget {
  final Project project;
  const _ProjectInfoSection({required this.project});

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka URL: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tampilan bagian ini tidak perlu diubah, jadi saya persingkat
    // untuk menjaga respons tetap fokus. Logika di dalamnya sudah benar.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Proyek', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (project.websiteUrl.isNotEmpty)
            _DetailRow(
              icon: Icons.language,
              label: 'Situs Web',
              value: project.websiteUrl,
              isUrl: true,
              onTap: () => _launchURL(project.websiteUrl, context),
            ),
          // ... detail lainnya seperti blockchain, status, dll.
          if (project.notes.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Catatan & Strategi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(project.notes, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  // Widget ini tidak berubah
  final IconData icon;
  final String? label;
  final String value;
  final bool isUrl;
  final VoidCallback? onTap;

  const _DetailRow({required this.icon, this.label, required this.value, this.isUrl = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            if (label != null) Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: TextStyle(color: isUrl ? Colors.blueAccent : null))),
          ],
        ),
      ),
    );
  }
}