// lib/features/dashboard/providers/dashboard_providers.dart

import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider ini akan mengambil SEMUA tugas dari SEMUA proyek aktif.
// Ini bisa menjadi operasi yang berat jika datanya banyak.
final allActiveTasksProvider = StreamProvider<List<Task>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Pantau stream proyek
  return firestoreService.getProjects().asyncMap((projects) async {
    // Filter hanya proyek yang aktif
    final activeProjects =
        projects.where((p) => p.status == ProjectStatus.active).toList();
    if (activeProjects.isEmpty) {
      return [];
    }

    // Ambil stream tugas untuk setiap proyek aktif
    final tasksFutures = activeProjects.map((project) {
      return firestoreService.getTasksForProject(project.id).first;
    }).toList();

    // Tunggu semua data tugas selesai dimuat
    final listOfTaskLists = await Future.wait(tasksFutures);

    // Gabungkan semua daftar tugas menjadi satu daftar besar
    return listOfTaskLists.expand((taskList) => taskList).toList();
  });
});


// Provider BARU yang lebih efisien untuk tugas hari ini
final todaysTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  // Pantau hasil dari provider di atas
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  // Lakukan pemfilteran hanya jika data sudah tersedia
  return allTasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final List<Task> todaysTasks = [];

    for (final task in tasks) {
      bool isDueToday = false;

      // Logika untuk menentukan apakah tugas jatuh tempo hari ini
      if (!task.isCompleted) {
        isDueToday = true;
      } else {
        if (task.lastCompletedTimestamp != null) {
          if (task.category == TaskCategory.Daily &&
              now.difference(task.lastCompletedTimestamp!).inHours >= 24) {
            isDueToday = true;
          } else if (task.category == TaskCategory.Weekly &&
              now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
            isDueToday = true;
          }
        }
      }

      if (isDueToday) {
        todaysTasks.add(task);
      }
    }

    // Urutkan tugas agar yang belum selesai muncul di atas
    todaysTasks.sort((a, b) => a.isCompleted ? 1 : -1);

    return todaysTasks;
  });
});