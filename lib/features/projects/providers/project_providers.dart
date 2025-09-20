// lib/features/projects/providers/project_providers.dart

import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

// Kelas penampung data tidak berubah
class ProjectTasks {
  final List<Task> today;
  final List<Task> tomorrow;
  final List<Task> oneTime;

  ProjectTasks({
    required this.today,
    required this.tomorrow,
    required this.oneTime,
  });
}

// --- PERUBAHAN UTAMA LOGIKA RESET DIMULAI DI SINI ---
final projectTasksProvider = Provider.family<AsyncValue<ProjectTasks>, String>((ref, projectId) {
  final tasksAsync = ref.watch(tasksStreamProvider(projectId));

  return tasksAsync.whenData((tasks) {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    
    // Mendefinisikan waktu reset untuk HARI INI pukul 7 pagi
    final todaysResetTime = tz.TZDateTime(location, now.year, now.month, now.day, 7);

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

      // Inisialisasi status tugas saat ini
      bool isEffectivelyCompleted = task.isCompleted;

      // Logika reset hanya berlaku untuk tugas yang sudah selesai (isCompleted = true)
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        final lastCompletedLocal = tz.TZDateTime.from(task.lastCompletedTimestamp!, location);

        if (task.category == TaskCategory.Daily) {
          // TUGAS HARIAN: di-reset jika diselesaikan SEBELUM jam 7 pagi HARI INI.
          if (lastCompletedLocal.isBefore(todaysResetTime)) {
            isEffectivelyCompleted = false; // Anggap belum selesai untuk hari ini
          }
        } else if (task.category == TaskCategory.Weekly) {
          // TUGAS MINGGUAN: di-reset jika sudah lewat 7 hari.
          if (now.difference(lastCompletedLocal).inDays >= 7) {
            isEffectivelyCompleted = false; // Anggap belum selesai untuk minggu ini
          }
        }
      }

      final taskToDisplay = Task(
        id: task.id,
        projectId: task.projectId,
        name: task.name,
        taskUrl: task.taskUrl,
        category: task.category,
        isCompleted: isEffectivelyCompleted, // Gunakan status efektif
        lastCompletedTimestamp: task.lastCompletedTimestamp,
      );

      // Tambahkan ke daftar yang sesuai
      if (!taskToDisplay.isCompleted) {
        todaysTasks.add(taskToDisplay);
        tomorrowsTasks.add(taskToDisplay);
      } else {
        // Jika sudah selesai HARI INI (setelah jam reset), tetap tampilkan di daftar hari ini
        todaysTasks.add(taskToDisplay);
        // Dan siapkan untuk besok dalam keadaan belum selesai
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

    // Pengurutan tidak berubah
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
