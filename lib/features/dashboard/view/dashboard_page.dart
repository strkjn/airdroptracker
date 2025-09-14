import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/services/firestore_service.dart';
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysTasksAsync = ref.watch(todaysTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Komando (Hari Ini)')),
      body: todaysTasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '🎉\nSemua tugas hari ini sudah selesai!\nKerja bagus!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            );
          }
          final projectsFuture = ref.watch(projectsStreamProvider.future);

          return FutureBuilder<List<Project>>(
            future: projectsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allProjects = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final projectName = allProjects
                      .firstWhere(
                        (p) => p.id == task.projectId,
                        orElse: () =>
                            Project(id: '', name: 'Proyek tidak ditemukan'),
                      )
                      .name;

                  return TaskCard(task: task, projectName: projectName);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi error: $err')),
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task, required this.projectName});

  final Task task;
  final String projectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... Logika untuk mengecek status task ...
    bool isCompleted = task.isCompleted;
    if (isCompleted && task.lastCompletedTimestamp != null) {
      final now = DateTime.now();
      if (task.category == TaskCategory.Daily &&
          now.difference(task.lastCompletedTimestamp!).inHours >= 24) {
        isCompleted = false;
      } else if (task.category == TaskCategory.Weekly &&
          now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
        isCompleted = false;
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: (newValue) {
          ref
              .read(firestoreServiceProvider)
              .updateTaskStatus(
                projectId: task.projectId,
                taskId: task.id,
                isCompleted: newValue!,
              );
        },
        title: Text(
          task.name,
          style: TextStyle(
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '$projectName • ${task.category.name}',
          style: TextStyle(color: isCompleted ? Colors.grey : Colors.white60),
        ),
      ),
    );
  }
}