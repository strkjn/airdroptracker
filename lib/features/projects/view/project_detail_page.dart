import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/projects/view/add_edit_project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

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
          isSameDay(task.lastCompletedTimestamp!, day);
    }).toList();
  }

  List<Task> _processTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.map((task) {
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        bool shouldReset = false;
        if (task.category == TaskCategory.Daily &&
            now.difference(task.lastCompletedTimestamp!).inHours >= 24) {
          shouldReset = true;
        } else if (task.category == TaskCategory.Weekly &&
            now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
          shouldReset = true;
        }
        if (shouldReset) {
          return Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false,
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          );
        }
      }
      return task;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsyncValue = ref.watch(tasksStreamProvider(widget.project.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditProjectPage(project: widget.project),
                ),
              );
            },
            tooltip: 'Edit Proyek',
          ),
          IconButton(
            icon: const Icon(Icons.library_add_check_outlined),
            onPressed: () => _showApplyTemplateDialog(context, ref, widget.project.id),
            tooltip: 'Terapkan Template',
          ),
        ],
      ),
      body: tasksAsyncValue.when(
        data: (originalTasks) {
          final tasks = _processTasks(originalTasks);
          final completedTasksOnSelectedDay = _getTasksForDay(_selectedDay!, tasks);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectInfoSection(project: widget.project),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text('Semua Tugas', style: Theme.of(context).textTheme.titleLarge),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  child: tasks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('Belum ada tugas di proyek ini.')),
                        )
                      : ListView.builder(
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
                        ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Kalender Aktivitas', style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  child: TableCalendar<Task>(
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    eventLoader: (day) => _getTasksForDay(day, tasks),
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
                ),
                const SizedBox(height: 16),
                if (completedTasksOnSelectedDay.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Aktivitas pada ${DateFormat.yMMMMd().format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: completedTasksOnSelectedDay.map((task) => ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(task.name),
                            subtitle: Text('Selesai pada ${DateFormat.Hm().format(task.lastCompletedTimestamp!)}'),
                          )).toList(),
                    ),
                  ),
                   const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat tugas: $err')),
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

class _ProjectInfoSection extends ConsumerWidget {
  final Project project;
  const _ProjectInfoSection({required this.project});

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
    final allWalletsAsync = ref.watch(walletsStreamProvider);
    final allSocialsAsync = ref.watch(socialAccountsStreamProvider);

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
                        label: 'Situs Web',
                        value: project.websiteUrl,
                        isUrl: true,
                        onTap: () => _launchURL(project.websiteUrl, context),
                      ),
                    if (project.blockchainNetwork.isNotEmpty)
                      _DetailRow(icon: Icons.lan_outlined, label: 'Jaringan', value: project.blockchainNetwork),
                    _DetailRow(icon: Icons.flag_outlined, label: 'Status', value: project.status.name),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', value: ''),
                    allWalletsAsync.when(
                      data: (wallets) {
                        final usedWallets = wallets.where((w) => project.associatedWalletIds.contains(w.id)).toList();
                        if (usedWallets.isEmpty) return const Padding(padding: EdgeInsets.only(left: 30, top: 4), child: Text('Tidak ada'));
                        return Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: usedWallets.map((w) => Text('${w.walletName} (${_shortenAddress(w.publicAddress)})', style: Theme.of(context).textTheme.bodyMedium)).toList(),
                          ),
                        );
                      },
                      loading: () => const Padding(padding: EdgeInsets.only(left: 30, top: 4), child: Text('Memuat...')),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.group_outlined, label: 'Akun', value: ''),
                    allSocialsAsync.when(
                      data: (socials) {
                        final usedSocials = socials.where((s) => project.associatedSocialAccountIds.contains(s.id)).toList();
                         if (usedSocials.isEmpty) return const Padding(padding: EdgeInsets.only(left: 30, top: 4), child: Text('Tidak ada'));
                        return Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: usedSocials.map((s) => Text('${s.username} (${s.platform.name})', style: Theme.of(context).textTheme.bodyMedium)).toList(),
                          ),
                        );
                      },
                      loading: () => const Padding(padding: EdgeInsets.only(left: 30, top: 4), child: Text('Memuat...')),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
           if (project.notes.isNotEmpty) ...[
             const Divider(height: 24),
             Text('Catatan & Strategi', style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             Container(
               padding: const EdgeInsets.all(12),
               width: double.infinity,
               decoration: BoxDecoration(
                 color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text(project.notes, style: Theme.of(context).textTheme.bodyMedium),
             ),
           ]
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final bool isUrl;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    this.label,
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
            Icon(icon, size: 18, color: isUrl ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            if (label != null) ...[
              Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
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