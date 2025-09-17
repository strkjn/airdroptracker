import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz; // Import timezone

// Provider allActiveTasksProvider tidak perlu diubah.
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
    final activeProjects = projects.where((p) => p.status == ProjectStatus.active);
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
final todaysTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  // 1. Dapatkan stream tugas mentah
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  // 2. Gunakan .whenData untuk memproses daftar tugas saat tersedia
  return allTasksAsync.whenData((tasks) {
    // Tentukan zona waktu lokal
    final location = tz.local;

    // Dapatkan waktu saat ini di zona waktu lokal
    final now = tz.TZDateTime.now(location);
    
    // Tentukan waktu reset hari ini (jam 7 pagi)
    final todaysResetTime = tz.TZDateTime(location, now.year, now.month, now.day, 7);

    // Tentukan "Hari Operasional"
    // Jika sekarang sebelum jam 7 pagi, "hari operasional" dimulai jam 7 pagi KEMARIN.
    // Jika sekarang setelah jam 7 pagi, "hari operasional" dimulai jam 7 pagi HARI INI.
    final startOfDashboardDay = now.isBefore(todaysResetTime)
        ? todaysResetTime.subtract(const Duration(days: 1))
        : todaysResetTime;

    final List<Task> processedTasks = [];

    for (final task in tasks) {
      bool needsReset = false;

      // Logika reset hanya berlaku untuk tugas yang sudah selesai
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        // Ubah timestamp penyelesaian ke zona waktu lokal untuk perbandingan yang akurat
        final lastCompletedLocal = tz.TZDateTime.from(task.lastCompletedTimestamp!, location);

        // Periksa apakah tugas diselesaikan SEBELUM awal "hari operasional" saat ini
        if (lastCompletedLocal.isBefore(startOfDashboardDay)) {
          if (task.category == TaskCategory.Daily) {
            needsReset = true;
          } else if (task.category == TaskCategory.Weekly) {
            // Untuk mingguan, kita tetap periksa selisih 7 hari
            if (now.difference(lastCompletedLocal).inDays >= 7) {
              needsReset = true;
            }
          }
        }
      }

      // Tambahkan tugas ke daftar yang akan ditampilkan
      // Tugas One-Time hanya muncul jika belum selesai.
      // Tugas Harian & Mingguan selalu muncul.
      bool shouldShow = true;
      if (task.category == TaskCategory.OneTime && task.isCompleted) {
        shouldShow = false;
      }

      if (shouldShow) {
        if (needsReset) {
          // Buat instance baru dari tugas dengan status isCompleted di-reset
          processedTasks.add(Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false, // Di-reset
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          ));
        } else {
          // Tambahkan tugas seperti aslinya
          processedTasks.add(task);
        }
      }
    }

    // Urutkan daftar agar tugas yang belum selesai selalu di atas
    processedTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return processedTasks;
  });
});