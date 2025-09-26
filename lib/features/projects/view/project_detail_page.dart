// lib/features/projects/view/project_detail_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/app_background.dart'; // <-- IMPORT BARU
import 'package:airdrop_flow/core/widgets/error_display.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/projects/providers/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:airdrop_flow/core/widgets/custom_form_dialog.dart';
import 'package:airdrop_flow/core/app_router.dart';
import '../providers/project_detail_providers.dart';

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

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.lastCompletedTimestamp == null) return false;
      return isSameDay(task.lastCompletedTimestamp, day);
    }).toList();
  }

  void _confirmDeleteProject(
      BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
              'Apakah Anda yakin ingin menghapus proyek "${project.name}"? Semua tugas di dalamnya juga akan terhapus.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () async {
                await ref
                    .read(firestoreServiceProvider)
                    .deleteProject(project.id);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(
      BuildContext context, WidgetRef ref, String projectId) {
    final nameController = TextEditingController();
    var selectedCategory = TaskCategory.OneTime;

    showCustomFormDialog(
        context: context,
        title: 'Tambah Tugas Baru',
        children: [
          TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Tugas'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tugas tidak boleh kosong.';
                }
                return null;
              }),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButtonFormField<TaskCategory>(
                value: selectedCategory,
                items: TaskCategory.values.map((TaskCategory category) {
                  return DropdownMenuItem<TaskCategory>(
                      value: category, child: Text(category.name));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setDialogState(() => selectedCategory = newValue);
                  }
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              );
            },
          ),
        ],
        onSave: () {
          ref.read(firestoreServiceProvider).addTaskToProject(
                projectId: projectId,
                taskName: nameController.text.trim(),
                category: selectedCategory,
              );
        });
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync =
        ref.watch(singleProjectStreamProvider(widget.projectId));

    // <-- WIDGET DITAMBAHKAN DI SINI -->
    // Membungkus .when() agar background tetap muncul saat loading/error
    return AppBackground(
      child: projectAsync.when(
        data: (project) {
          final projectTasksAsync = ref.watch(projectTasksProvider(project.id));
          final allTasksForCalendarAsync =
              ref.watch(tasksStreamProvider(project.id));

          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            // <-- MODIFIKASI: Latar belakang dibuat transparan -->
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
                  onPressed: () {
                    AppRouter.goToEditProject(context, project);
                  },
                  tooltip: 'Edit Proyek',
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
                        child: Text('Kalender Aktivitas',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const SizedBox(height: 8),
                      allTasksForCalendarAsync.when(
                        data: (allTasks) {
                          final completedTasksOnSelectedDay = selectedDay != null
                              ? _getTasksForDay(selectedDay, allTasks)
                              : <Task>[];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlassContainer(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: TableCalendar<Task>(
                                  calendarFormat: CalendarFormat.week,
                                  firstDay: DateTime.utc(2022, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_selectedDay, day),
                                  startingDayOfWeek: StartingDayOfWeek.monday,
                                  eventLoader: (day) =>
                                      _getTasksForDay(day, allTasks),
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
                                    selectedDecoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle),
                                    todayDecoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    markerBuilder: (context, date, events) {
                                      if (events.isNotEmpty) {
                                        return Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: colorScheme.secondary
                                                      .withOpacity(0.8)),
                                              width: 7,
                                              height: 7,
                                            ));
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              if (selectedDay != null &&
                                  completedTasksOnSelectedDay.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                      'Aktivitas pada ${DateFormat.yMMMMd('id_ID').format(selectedDay)}',
                                      style:
                                          Theme.of(context).textTheme.titleLarge),
                                ),
                                const SizedBox(height: 8),
                                GlassContainer(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: completedTasksOnSelectedDay
                                        .map((task) => ListTile(
                                              leading: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green),
                                              title: Text(task.name),
                                              subtitle: task
                                                          .lastCompletedTimestamp !=
                                                      null
                                                  ? Text(
                                                      'Selesai pada ${DateFormat.Hm().format(task.lastCompletedTimestamp!)}')
                                                  : null,
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => ErrorDisplay(
                          errorMessage: err.toString(),
                          onRetry: () =>
                              ref.invalidate(tasksStreamProvider(project.id)),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorDisplay(
                  errorMessage: 'Gagal memuat daftar tugas.\n${err.toString()}',
                  onRetry: () => ref.invalidate(projectTasksProvider(project.id))),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context, ref, project.id),
              tooltip: 'Tambah Tugas Manual',
              child: const Icon(Icons.add_task),
            ),
          );
        },
        loading: () => Scaffold(
            backgroundColor: Colors.transparent, // <-- MODIFIKASI
            appBar: AppBar(
              backgroundColor: Colors.transparent, // <-- MODIFIKASI
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(
          backgroundColor: Colors.transparent, // <-- MODIFIKASI
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: Colors.transparent, // <-- MODIFIKASI
            elevation: 0,
          ),
          body: ErrorDisplay(
            errorMessage: 'Gagal memuat proyek.\n${err.toString()}',
            onRetry: () =>
                ref.invalidate(singleProjectStreamProvider(widget.projectId)),
          ),
        ),
      ),
    );
  }
}

// ... (Sisa kode widget _TaskListSection, TaskTile, dll. tidak ada perubahan)
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
                  ref
                      .read(firestoreServiceProvider)
                      .deleteTask(projectId: task.projectId, taskId: task.id);
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

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, required this.isEnabled});
  final Task task;
  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCompleted = task.isCompleted;
    
    final Color textColor =
        isEnabled ? (isCompleted ? Colors.grey : Colors.white) : Colors.grey;
    final nextResetDate =
        task.lastCompletedTimestamp?.add(const Duration(days: 1));

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: CheckboxListTile(
        title: Text(
          task.name,
          style: TextStyle(
            decoration:
                isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.amber),
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

class _ProjectInfoSection extends ConsumerWidget {
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

  String _shortenAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 5)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final associatedDataAsync = ref.watch(projectAssociatedDataProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Proyek', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (project.websiteUrl.isNotEmpty)
                      _DetailRow(
                        icon: Icons.language,
                        value: project.websiteUrl,
                        isUrl: true,
                        onTap: () => _launchURL(project.websiteUrl, context),
                      ),
                    if (project.blockchainNetwork.isNotEmpty)
                      _DetailRow(
                          icon: Icons.lan_outlined,
                          value: project.blockchainNetwork),
                    _DetailRow(
                        icon: Icons.flag_outlined, value: project.status.name),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    associatedDataAsync.when(
                      data: (data) {
                        final usedWallets = data.wallets
                            .where((w) =>
                                project.associatedWalletIds.contains(w.id))
                            .toList();
                        final usedSocials = data.socialAccounts
                            .where((s) => project.associatedSocialAccountIds
                                .contains(s.id))
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssociatedItemsList(
                              icon: Icons.account_balance_wallet_outlined,
                              items: usedWallets
                                  .map((w) =>
                                      '${w.walletName} (${_shortenAddress(w.publicAddress)})')
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            _AssociatedItemsList(
                              icon: Icons.group_outlined,
                              items: usedSocials
                                  .map((s) =>
                                      '${s.username} (${s.platform.name})')
                                  .toList(),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.0)),
                      error: (e, s) => Text('Gagal memuat data wallet/sosial',
                          style: TextStyle(color: Colors.red.shade300)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (project.notes.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Catatan & Strategi',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(project.notes,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssociatedItemsList extends StatelessWidget {
  const _AssociatedItemsList({required this.icon, required this.items});
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _DetailRow(icon: icon, value: 'Tidak ada');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items.map((item) => _DetailRow(icon: icon, value: item)).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isUrl;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.value,
    this.isUrl = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color:
                    isUrl ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isUrl ? colorScheme.primary : null,
                  decoration: isUrl ? TextDecoration.underline : null,
                  decorationColor: colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}