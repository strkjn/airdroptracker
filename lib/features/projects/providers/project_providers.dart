// lib/features/projects/providers/project_providers.dart

import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
// --- PERBAIKAN DI SINI ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

// 1. Buat class untuk menampung tugas yang sudah terstruktur
class ProjectTasks {
  final List<Task> today;
  final List<Task> tomorrow;
  final List<Task> oneTime; // Tugas OneTime yang belum selesai

  ProjectTasks({
    required this.today,
    required this.tomorrow,
    required this.oneTime,
  });
}

// 2. Ganti nama provider agar lebih deskriptif
final projectTasksProvider =
    Provider.family<AsyncValue<ProjectTasks>, String>((ref, projectId) {

  // Pantau AsyncValue dari stream provider, BUKAN stream-nya langsung
  final tasksAsync = ref.watch(tasksStreamProvider(projectId));

  // Gunakan .whenData untuk memproses daftar tugas saat tersedia
  return tasksAsync.whenData((tasks) {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);

    final todaysResetTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 7);

    final startOfToday = now.isBefore(todaysResetTime)
        ? todaysResetTime.subtract(const Duration(days: 1))
        : todaysResetTime;
    final endOfToday = startOfToday.add(const Duration(days: 1));

    final List<Task> todaysTasks = [];
    final List<Task> tomorrowsTasks = [];
    final List<Task> oneTimeTasks = [];

    for (final task in tasks) {
      if (task.category == TaskCategory.OneTime) {
        if (!task.isCompleted) {
          oneTimeTasks.add(task);
        }
        continue;
      }

      if (task.lastCompletedTimestamp == null) {
        todaysTasks.add(task);
        continue;
      }

      final lastCompletedLocal =
          tz.TZDateTime.from(task.lastCompletedTimestamp!, location);

      bool needsReset = false;
      if (task.isCompleted) {
        if (task.category == TaskCategory.Daily) {
          if (lastCompletedLocal.isBefore(startOfToday)) {
            needsReset = true;
          }
        } else if (task.category == TaskCategory.Weekly) {
          if (now.difference(lastCompletedLocal).inDays >= 7) {
            needsReset = true;
          }
        }
      }

      final taskToDisplay = needsReset
          ? Task(
              id: task.id,
              projectId: task.projectId,
              name: task.name,
              taskUrl: task.taskUrl,
              category: task.category,
              isCompleted: false, // Di-reset
              lastCompletedTimestamp: task.lastCompletedTimestamp,
            )
          : task;

      if (!taskToDisplay.isCompleted) {
        todaysTasks.add(taskToDisplay);
        tomorrowsTasks.add(taskToDisplay);
      } else {
        if (!lastCompletedLocal.isBefore(startOfToday) &&
            lastCompletedLocal.isBefore(endOfToday)) {
          todaysTasks.add(taskToDisplay);
          tomorrowsTasks.add(Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false,
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          ));
        }
      }
    }

    // Urutkan semua list
    todaysTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });
    tomorrowsTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return ProjectTasks(
      today: todaysTasks,
      tomorrow: tomorrowsTasks,
      oneTime: oneTimeTasks,
    );
  });
});