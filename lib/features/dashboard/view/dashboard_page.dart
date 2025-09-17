import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysTasksAsync = ref.watch(todaysTasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: todaysTasksAsync.when(
        data: (dashboardData) {
          final overdueTasks = dashboardData.overdueTasks;
          final todaysTasks = dashboardData.todaysTasks;

          if (overdueTasks.isEmpty && todaysTasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '👍\nTidak ada tugas aktif untuk hari ini.\nSaatnya bersantai atau cari peluang baru!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            );
          }
          
          final allTasks = [...overdueTasks, ...todaysTasks];
          final totalTasks = allTasks.length;
          final completedTasks = allTasks.where((task) => task.isCompleted).length;
          final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

          return ListView(
            padding: const EdgeInsets.only(bottom: 16.0),
            children: [
              _ProgressCard(
                progress: progress,
                completedCount: completedTasks,
                totalCount: totalTasks,
              ),

              // --- BAGIAN UNTUK SISA TUGAS KEMARIN ---
              if (overdueTasks.isNotEmpty) ...[
                _DateHeader(
                  title: "Sisa Tugas: ${DateFormat('EEEE, d MMMM', 'id_ID').format(dashboardData.overdueDate)}",
                  isOverdue: true,
                ),
                ...overdueTasks.map((task) => TaskCard(task: task)).toList(),
              ],

              // --- BAGIAN UNTUK TUGAS HARI INI ---
              if (todaysTasks.isNotEmpty) ...[
                _DateHeader(
                   title: "Tugas Hari Ini: ${DateFormat('EEEE, d MMMM', 'id_ID').format(dashboardData.todaysDate)}",
                ),
                ...todaysTasks.map((task) => TaskCard(task: task)).toList(),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi error: $err')),
      ),
    );
  }
}

// --- BARU: Widget untuk header tanggal ---
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.title, this.isOverdue = false});
  final String title;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isOverdue ? Colors.orangeAccent : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Keseluruhan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount dari $totalCount tugas selesai',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

final projectProvider = FutureProvider.family<Project?, String>((ref, projectId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProjectById(projectId);
});

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});
  final Task task;

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka URL: $urlString')),
      );
    }
  }

  String _shortenUrl(String url, {int maxLength = 25, int startLength = 12, int endLength = 8}) {
    if (url.length <= maxLength) {
      return url;
    }
    String cleanUrl = url.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?'), '');
    if (cleanUrl.length <= maxLength) {
      return cleanUrl;
    }

    final start = cleanUrl.substring(0, startLength);
    final end = cleanUrl.substring(cleanUrl.length - endLength);
    return '$start...$end';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(task.projectId));
    
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0, 8.0),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (newValue) {
              ref
                  .read(firestoreServiceProvider)
                  .updateTaskStatus(
                    projectId: task.projectId,
                    taskId: task.id,
                    isCompleted: newValue!,
                  );
            },
          ),
          Expanded(
            child: projectAsync.when(
              data: (project) {
                if (project == null) {
                  return Text('Proyek untuk tugas "${task.name}" tidak ditemukan');
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted ? Colors.grey : null,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (project.websiteUrl.isNotEmpty)
                          InkWell(
                             onTap: () => _launchURL(project.websiteUrl, context),
                             child: Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
                               child: Text(
                                 _shortenUrl(project.websiteUrl),
                                 textAlign: TextAlign.right,
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                   color: Theme.of(context).colorScheme.primary,
                                   decoration: TextDecoration.underline,
                                   decorationColor: Theme.of(context).colorScheme.primary,
                                 ),
                               ),
                             ),
                          ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              ),
              error: (err, stack) => const Text('Error memuat proyek'),
            ),
          ),
          if (task.taskUrl.isNotEmpty)
            IconButton(
              icon: Icon(Icons.link, color: Theme.of(context).colorScheme.secondary),
              tooltip: 'Buka Tautan Tugas',
              onPressed: () => _launchURL(task.taskUrl, context),
            ),
        ],
      ),
    );
  }
}