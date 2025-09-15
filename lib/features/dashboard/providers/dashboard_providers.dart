import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// --- PERBAIKAN UTAMA ADA DI SINI ---
final todaysTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  return ref.watch(allActiveTasksProvider).whenData((tasks) {
    final now = DateTime.now();
    final todaysResetTime = DateTime(now.year, now.month, now.day, 7);
    final startOfDashboardDay = now.isBefore(todaysResetTime)
        ? todaysResetTime.subtract(const Duration(days: 1))
        : todaysResetTime;

    final List<Task> todaysTasks = [];

    for (final task in tasks) {
      bool isTodaysTask = false;
      bool needsReset = false;

      // Hanya periksa reset jika tugas sudah selesai
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        
        // ==== FIX: LOGIKA RESET SEKARANG HANYA UNTUK DAILY & WEEKLY ====
        if (task.category == TaskCategory.Daily) {
          if (task.lastCompletedTimestamp!.isBefore(startOfDashboardDay)) {
            needsReset = true;
          }
        } else if (task.category == TaskCategory.Weekly) {
          if (now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
            needsReset = true;
          }
        }
        // Tugas OneTime akan dilewati, sehingga 'needsReset' tetap false.
      }

      // Tentukan apakah tugas harus ditampilkan di dashboard hari ini
      switch (task.category) {
        case TaskCategory.OneTime:
          // TUGAS ONETIME HANYA MUNCUL JIKA BELUM SELESAI.
          if (!task.isCompleted) {
            isTodaysTask = true;
          }
          break;
        case TaskCategory.Daily:
        case TaskCategory.Weekly:
          // Tugas harian & mingguan selalu relevan untuk ditampilkan.
          isTodaysTask = true;
          break;
      }
      
      if (isTodaysTask) {
        if (needsReset) {
          todaysTasks.add(Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false, // Status di-reset
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          ));
        } else {
          todaysTasks.add(task);
        }
      }
    }

    // Urutkan daftar agar tugas yang belum selesai ada di atas
    todaysTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return todaysTasks;
  });
});