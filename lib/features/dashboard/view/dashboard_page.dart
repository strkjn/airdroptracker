// lib/features/dashboard/view/dashboard_page.dart

import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:airdrop_flow/core/models/project_model.dart';


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardTasksAsync = ref.watch(dashboardTasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 24),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: dashboardTasksAsync.when(
                      data: (data) {
                         final todaysTasks = data.today;
                         final total = todaysTasks.length;
                         final completed = todaysTasks.where((t) => t.isCompleted).length;
                         final progress = total > 0 ? completed / total : 0.0;
                        return _ProgressCard(progress: progress);
                      },
                      loading: () => const _ProgressCard(progress: 0),
                      error: (e,s) => const _ProgressCard(progress: 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: dashboardTasksAsync.when(
                            data: (data) {
                              final todaysTasks = data.today;
                              final total = todaysTasks.length;
                              final completed = todaysTasks.where((t) => t.isCompleted).length;
                              return _InfoCard(
                                title: 'Task selesai',
                                value: '$completed/$total',
                                subtitle: '9 September 2025', // Placeholder
                              );
                            },
                             loading: () => const _InfoCard(title: 'Task selesai', value: '-/-'),
                             error: (e,s) => const _InfoCard(title: 'Task selesai', value: 'Error'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 1,
                          child: ref.watch(projectsStreamProvider).when(
                            data: (projects) => _InfoCard(
                              title: 'Total Projek',
                              value: projects.length.toString(),
                            ),
                            loading: () => const _InfoCard(title: 'Total Projek', value: '-'),
                            error: (e,s) => const _InfoCard(title: 'Total Projek', value: 'Error'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            dashboardTasksAsync.when(
              data: (data) => Column(
                children: [
                  _TaskListCard(title: 'Task hari ini', tasks: data.today, isEnabled: true),
                  const SizedBox(height: 16),
                  _TaskListCard(title: 'Task besok', tasks: data.tomorrow, isEnabled: false),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Gagal memuat tasks'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET-WIDGET HEADER & INFO CARD (TIDAK BERUBAH) ---

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hallo !',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'nama user', // Placeholder
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Progres hari ini',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 128,
              height: 128,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  backgroundColor: Colors.purple.shade700.withOpacity(0.5),
                  progressColor: Colors.cyan.shade400,
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value, this.subtitle});
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.6)),
              ),
          ],
        ),
      ),
    );
  }
}


// --- WIDGET TASK LIST CARD (DIPERBARUI TOTAL) ---

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({required this.title, required this.tasks, required this.isEnabled});
  final String title;
  final List<Task> tasks;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN PADDING ATAS & BAWAH DI SINI ---
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Membuat tinggi kartu menyesuaikan konten
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.purpleAccent),
                ),
              ),
            ],
          ),
          // Mengurangi jarak setelah judul
          const SizedBox(height: 4), 
          // Header tabel
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                // --- PERBAIKAN PROPorsi FLEX DI SINI ---
                const Expanded(flex: 5, child: Text('Projek', style: TextStyle(color: Colors.white70, fontSize: 12))),
                const Expanded(flex: 5, child: Text('Task', style: TextStyle(color: Colors.white70, fontSize: 12))),
                const Expanded(flex: 2, child: Text('Url', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                const Expanded(flex: 3, child: Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text('Tidak ada tugas.'),
            )
          else
            Column(
              children: tasks
                  .take(3)
                  .map((task) => _TaskListItem(task: task, isEnabled: isEnabled))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _TaskListItem extends ConsumerWidget {
  const _TaskListItem({required this.task, required this.isEnabled});
  final Task task;
  final bool isEnabled;

  Future<void> _launchURL(String urlString, BuildContext context) async {
    if (urlString.isEmpty) return;
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
    final projectAsync = ref.watch(singleProjectStreamProvider(task.projectId));

    return projectAsync.when(
      data: (project) => SizedBox(
        height: 30, // Memberi tinggi tetap pada setiap baris agar rapi
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- PERBAIKAN PROPorsi FLEX DI SINI ---
            Expanded(flex: 5, child: Text(project.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: isEnabled ? Colors.white : Colors.grey.shade600))),
            Expanded(flex: 5, child: Text(task.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: isEnabled ? Colors.white : Colors.grey.shade600))),
            Expanded(
              flex: 2,
              child: (task.taskUrl.isNotEmpty)
                  ? IconButton(
                      icon: Icon(Icons.link, color: isEnabled ? Colors.purpleAccent : Colors.grey.shade700, size: 20),
                      onPressed: isEnabled ? () => _launchURL(task.taskUrl, context) : null,
                      splashRadius: 20,
                      tooltip: 'Buka tautan tugas',
                    )
                  : const SizedBox(),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Checkbox(
                  value: task.isCompleted,
                  visualDensity: VisualDensity.compact,
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
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 48),
      error: (e, s) => const SizedBox(height: 48),
    );
  }
}


// Custom Painter (TIDAK BERUBAH)
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}