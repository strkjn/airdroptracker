// lib/features/dashboard/providers/dashboard_providers.dart

import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

// Kelas penampung data tidak berubah
class DashboardTasks {
  final List<Task> today;
  final List<Task> tomorrow;

  DashboardTasks({required this.today, required this.tomorrow});
}

// Provider untuk mengambil semua tugas aktif tidak berubah
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


// --- PERUBAHAN UTAMA LOGIKA RESET DIMULAI DI SINI ---
final dashboardTasksProvider = Provider<AsyncValue<DashboardTasks>>((ref) {
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  return allTasksAsync.whenData((tasks) {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);

    // Mendefinisikan waktu reset untuk HARI INI pukul 7 pagi
    final todaysResetTime = tz.TZDateTime(location, now.year, now.month, now.day, 7);

    final List<Task> todaysTasks = [];
    final List<Task> tomorrowsTasks = [];

    for (final task in tasks) {
      // Tugas 'OneTime' hanya muncul di daftar hari ini jika belum selesai
      if (task.category == TaskCategory.OneTime) {
        if (!task.isCompleted) {
          todaysTasks.add(task);
        }
        continue; // Lanjut ke tugas berikutnya
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
          // TUGAS MINGGUAN: di-reset jika sudah lewat 7 hari. Logika ini tetap.
          if (now.difference(lastCompletedLocal).inDays >= 7) {
            isEffectivelyCompleted = false; // Anggap belum selesai untuk minggu ini
          }
        }
      }

      // Buat objek tugas baru dengan status yang sudah disesuaikan
      final currentTaskState = Task(
        id: task.id,
        projectId: task.projectId,
        name: task.name,
        taskUrl: task.taskUrl,
        category: task.category,
        isCompleted: isEffectivelyCompleted, // Gunakan status efektif
        lastCompletedTimestamp: task.lastCompletedTimestamp,
      );

      // Tambahkan ke daftar tugas hari ini
      todaysTasks.add(currentTaskState);

      // Semua tugas berulang akan muncul lagi besok dalam keadaan belum selesai
      tomorrowsTasks.add(Task(
        id: task.id,
        projectId: task.projectId,
        name: task.name,
        taskUrl: task.taskUrl,
        category: task.category,
        isCompleted: false, // Untuk besok, semua dianggap belum selesai
        lastCompletedTimestamp: task.lastCompletedTimestamp,
      ));
    }

    // Pengurutan tidak berubah, yang belum selesai selalu di atas.
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
