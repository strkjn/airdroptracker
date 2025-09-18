// lib/features/dashboard/providers/dashboard_providers.dart

import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

// 1. Definisikan sebuah kelas untuk menampung hasil tugas yang sudah diproses
class DashboardTasks {
  final List<Task> today;
  final List<Task> tomorrow;

  DashboardTasks({required this.today, required this.tomorrow});
}

// Provider allActiveTasksProvider tidak perlu diubah, sudah sangat baik.
final allActiveTasksProvider = StreamProvider<List<Task>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final controller = StreamController<List<Task>>();

  final taskDataCache = <String, List<Task>>{};
  final taskSubscriptions = <String, StreamSubscription>{};

  void pushUpdatedTasks() {
    final allTasks = taskDataCache.values.expand((tasks) => tasks).toList();
    if (!controller.isClosed) {
      controller.add(allTasks);
    }
  }

  final projectsSubscription = firestoreService.getProjects().listen((projects) {
    final activeProjects =
        projects.where((p) => p.status == ProjectStatus.active);
    final activeProjectIds = activeProjects.map((p) => p.id).toSet();

    final oldIds = taskSubscriptions.keys.toSet();
    final removedIds = oldIds.difference(activeProjectIds);
    for (final id in removedIds) {
      taskSubscriptions[id]?.cancel();
      taskSubscriptions.remove(id);
      taskDataCache.remove(id);
    }

    for (final project in activeProjects) {
      if (!taskSubscriptions.containsKey(project.id)) {
        taskSubscriptions[project.id] =
            firestoreService.getTasksForProject(project.id).listen((tasks) {
          taskDataCache[project.id] = tasks;
          pushUpdatedTasks();
        });
      }
    }
    pushUpdatedTasks();
  });

  ref.onDispose(() {
    projectsSubscription.cancel();
    for (final sub in taskSubscriptions.values) {
      sub.cancel();
    }
    controller.close();
  });

  return controller.stream;
});

// --- PERUBAHAN UTAMA ADA DI SINI ---
// 2. Ubah nama provider agar lebih deskriptif dan kembalikan object DashboardTasks
final dashboardTasksProvider = Provider<AsyncValue<DashboardTasks>>((ref) {
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  return allTasksAsync.whenData((tasks) {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);

    // --- Definisi Waktu ---
    // Waktu reset hari ini (jam 7 pagi)
    final todaysResetTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 7);
    // Waktu reset besok (jam 7 pagi)
    final tomorrowsResetTime = todaysResetTime.add(const Duration(days: 1));

    // --- Definisi Hari Operasional ---
    // Awal hari operasional saat ini
    final startOfToday = now.isBefore(todaysResetTime)
        ? todaysResetTime.subtract(const Duration(days: 1))
        : todaysResetTime;
    // Akhir hari operasional saat ini (sama dengan awal hari operasional besok)
    final endOfToday = startOfToday.add(const Duration(days: 1));

    final List<Task> todaysTasks = [];
    final List<Task> tomorrowsTasks = [];

    for (final task in tasks) {
      // Hanya proses tugas Harian (Daily) dan Mingguan (Weekly)
      if (task.category == TaskCategory.OneTime) {
        // Tugas One-Time hanya muncul jika belum selesai
        if (!task.isCompleted) {
          todaysTasks.add(task);
        }
        continue; // Lanjut ke iterasi berikutnya
      }

      // Jika tugas belum pernah selesai sama sekali, anggap itu tugas hari ini.
      if (task.lastCompletedTimestamp == null) {
        todaysTasks.add(task);
        continue;
      }

      final lastCompletedLocal =
          tz.TZDateTime.from(task.lastCompletedTimestamp!, location);

      // --- Logika Reset ---
      bool needsReset = false;
      if (task.isCompleted) {
        if (task.category == TaskCategory.Daily) {
          // Jika diselesaikan SEBELUM awal hari ini, maka perlu di-reset.
          if (lastCompletedLocal.isBefore(startOfToday)) {
            needsReset = true;
          }
        } else if (task.category == TaskCategory.Weekly) {
          // Jika sudah lebih dari 7 hari, perlu di-reset.
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
              isCompleted: false, // Status di-reset
              lastCompletedTimestamp: task.lastCompletedTimestamp,
            )
          : task;

      // --- Penempatan Tugas (Hari Ini atau Besok) ---
      // Jika tugas belum selesai atau baru saja di-reset
      if (!taskToDisplay.isCompleted) {
        todaysTasks.add(taskToDisplay);
        // Tugas yang sama juga akan muncul besok
        tomorrowsTasks.add(taskToDisplay);
      }
      // Jika tugas sudah selesai...
      else {
        // ...dan diselesaikan dalam rentang hari operasional ini.
        if (!lastCompletedLocal.isBefore(startOfToday) &&
            lastCompletedLocal.isBefore(endOfToday)) {
          // Tugas tetap muncul hari ini (dalam keadaan selesai).
          todaysTasks.add(taskToDisplay);
          // Dan akan muncul lagi besok (dalam keadaan belum selesai).
          tomorrowsTasks.add(Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false, // Akan di-reset besok
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          ));
        }
      }
    }

    // Urutkan kedua list agar yang belum selesai selalu di atas
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

    return DashboardTasks(today: todaysTasks, tomorrow: tomorrowsTasks);
  });
});