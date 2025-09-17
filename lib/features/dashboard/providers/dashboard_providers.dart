import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart'; // <-- TAMBAHKAN IMPORT INI

// --- Model DashboardTasks tidak berubah ---
class DashboardTasks {
  final List<Task> overdueTasks;
  final List<Task> todaysTasks;
  final DateTime todaysDate;
  final DateTime overdueDate;

  DashboardTasks({
    required this.overdueTasks,
    required this.todaysTasks,
    required this.todaysDate,
    required this.overdueDate,
  });
}

// --- PERBAIKAN UTAMA: allActiveTasksProvider ditulis ulang agar lebih andal ---
final allActiveTasksProvider = StreamProvider<List<Task>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // 1. Ambil stream dari daftar proyek
  return ref.watch(projectsStreamProvider).when(
    data: (projects) {
      final activeProjects = projects.where((p) => p.status == ProjectStatus.active);

      if (activeProjects.isEmpty) {
        // Jika tidak ada proyek aktif, kembalikan stream dengan daftar kosong
        return Stream.value([]);
      }

      // 2. Buat daftar stream tugas untuk setiap proyek aktif
      final listOfStreams = activeProjects
          .map((p) => firestoreService.getTasksForProject(p.id))
          .toList();

      // 3. Gabungkan semua stream tugas menjadi satu stream besar
      // Setiap kali salah satu stream tugas diperbarui, stream gabungan ini akan mengeluarkan data baru
      return Rx.combineLatest(listOfStreams, (List<List<Task>> allTasksLists) {
        // Gabungkan semua daftar tugas menjadi satu daftar besar
        return allTasksLists.expand((tasks) => tasks).toList();
      });
    },
    // Sediakan nilai default saat proyek sedang dimuat atau jika ada error
    loading: () => Stream.value([]),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  );
});


// --- Logika di bawah ini tidak perlu diubah, tapi saya sertakan agar lengkap ---
final todaysTasksProvider = Provider<AsyncValue<DashboardTasks>>((ref) {
  return ref.watch(allActiveTasksProvider).whenData((tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todaysResetTime = DateTime(today.year, today.month, today.day, 7);
    final yesterdaysResetTime = todaysResetTime.subtract(const Duration(days: 1));

    final List<Task> todaysApplicableTasks = [];
    final List<Task> yesterdaysOverdueTasks = [];

    for (final task in tasks) {
      bool isTodaysTask = false;
      bool needsResetForToday = false;
      
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        if (task.category == TaskCategory.Daily && task.lastCompletedTimestamp!.isBefore(todaysResetTime)) {
          needsResetForToday = true;
        } else if (task.category == TaskCategory.Weekly && now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
          needsResetForToday = true;
        }
      }

      switch (task.category) {
        case TaskCategory.OneTime:
          if (!task.isCompleted) isTodaysTask = true;
          break;
        case TaskCategory.Daily:
        case TaskCategory.Weekly:
          isTodaysTask = true;
          break;
      }
      
      if (isTodaysTask) {
        todaysApplicableTasks.add(
          needsResetForToday
            ? Task(id: task.id, projectId: task.projectId, name: task.name, taskUrl: task.taskUrl, category: task.category, isCompleted: false, lastCompletedTimestamp: task.lastCompletedTimestamp)
            : task
        );
      }

      if (now.isBefore(todaysResetTime)) {
        if (task.category == TaskCategory.Daily) {
          final bool isNotCompleted = !task.isCompleted;
          final bool completedBeforeYesterdaysReset = task.isCompleted && task.lastCompletedTimestamp != null && task.lastCompletedTimestamp!.isBefore(yesterdaysResetTime);

          if (isNotCompleted || completedBeforeYesterdaysReset) {
            yesterdaysOverdueTasks.add(
              Task(id: task.id, projectId: task.projectId, name: task.name, taskUrl: task.taskUrl, category: task.category, isCompleted: false, lastCompletedTimestamp: task.lastCompletedTimestamp)
            );
          }
        }
      }
    }
    
    final todaysTaskIds = todaysApplicableTasks.map((t) => t.id).toSet();
    yesterdaysOverdueTasks.removeWhere((t) => todaysTaskIds.contains(t.id));

    todaysApplicableTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return DashboardTasks(
      todaysDate: today,
      overdueDate: yesterday,
      todaysTasks: todaysApplicableTasks,
      overdueTasks: yesterdaysOverdueTasks,
    );
  });
});