// lib/features/dashboard/view/dashboard_page.dart

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
    // 1. Panggil provider yang baru: dashboardTasksProvider
    final dashboardTasksAsync = ref.watch(dashboardTasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: dashboardTasksAsync.when(
        data: (data) {
          final todaysTasks = data.today;
          final tomorrowsTasks = data.tomorrow;

          if (todaysTasks.isEmpty && tomorrowsTasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '👍\nTidak ada tugas aktif.\nSaatnya bersantai atau cari peluang baru!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            );
          }

          final totalTasks = todaysTasks.length;
          final completedTasks =
              todaysTasks.where((task) => task.isCompleted).length;
          final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

          // 2. Gunakan CustomScrollView untuk menggabungkan beberapa list
          return CustomScrollView(
            slivers: [
              // Kartu Progres tetap di atas
              SliverToBoxAdapter(
                child: _ProgressCard(
                  progress: progress,
                  completedCount: completedTasks,
                  totalCount: totalTasks,
                ),
              ),

              // --- Bagian Tugas Hari Ini ---
              if (todaysTasks.isNotEmpty) ...[
                _buildSectionHeader(context, "Tugas Hari Ini"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = todaysTasks[index];
                      return TaskCard(task: task, isEnabled: true); // Tugas hari ini selalu aktif
                    },
                    childCount: todaysTasks.length,
                  ),
                ),
              ],

              // --- Bagian Tugas Besok ---
              if (tomorrowsTasks.isNotEmpty) ...[
                _buildSectionHeader(context, "Akan Datang Besok"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tomorrowsTasks[index];
                      // Tugas besok dinonaktifkan
                      return TaskCard(
                        task: task,
                        isEnabled: false,
                        // Menambahkan tanggal reset berikutnya
                        nextResetDate: task.lastCompletedTimestamp,
                      );
                    },
                    childCount: tomorrowsTasks.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Spacer di bawah
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Terjadi error saat memuat tugas: $err')),
      ),
    );
  }

  // Helper widget untuk judul setiap bagian
  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
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
            'Progres Hari Ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.white.withAlpha(50),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

final projectProvider =
    FutureProvider.family<Project?, String>((ref, projectId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProjectById(projectId);
});

// 3. Modifikasi TaskCard untuk menerima parameter isEnabled
class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isEnabled,
    this.nextResetDate,
  });
  final Task task;
  final bool isEnabled;
  final DateTime? nextResetDate;

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
    if (url.length <= maxLength) return url;
    String cleanUrl = url.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?'), '');
    if (cleanUrl.length <= maxLength) return cleanUrl;
    final start = cleanUrl.substring(0, startLength);
    final end = cleanUrl.substring(cleanUrl.length - endLength);
    return '$start...$end';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(task.projectId));
    final bool isCompleted = isEnabled ? task.isCompleted : false;
    final Color textColor = isEnabled ? (isCompleted ? Colors.grey : Colors.white) : Colors.grey;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6, // Buat kartu tugas besok terlihat redup
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0, 8.0),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              // Nonaktifkan checkbox jika isEnabled false
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
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 4. Tampilkan tanggal reset untuk tugas besok
                          if (!isEnabled && nextResetDate != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                DateFormat('d MMM', 'id_ID').format(nextResetDate!.add(const Duration(days: 1))),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.amber),
                              ),
                            )
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
      ),
    );
  }
}