// lib/features/projects/providers/project_providers.dart

import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- KODE YANG DIPERBARUI DAN DISEMPURNAKAN ---

// Mengubah dari Provider menjadi StreamProvider yang benar.
// Ini adalah cara yang tepat untuk mengubah (transform) data dari stream lain.
final processedTasksProvider =
    StreamProvider.family<List<Task>, String>((ref, projectId) {
  // 1. Pantau stream tugas asli dari Firestore.
  final tasksStream = ref.watch(tasksStreamProvider(projectId));

  // 2. Gunakan .map() pada stream untuk mengubah setiap daftar tugas yang masuk.
  //    Ini akan secara otomatis menangani status loading/error dari stream asli.
  return tasksStream.map((tasks) {
    final now = DateTime.now();

    // 3. Logika pemrosesan Anda untuk mereset tugas harian/mingguan.
    return tasks.map((task) {
      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        bool shouldReset = false;

        if (task.category == TaskCategory.Daily &&
            now.difference(task.lastCompletedTimestamp!).inHours >= 24) {
          shouldReset = true;
        } else if (task.category == TaskCategory.Weekly &&
            now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
          shouldReset = true;
        }

        if (shouldReset) {
          // Buat instance Task baru dengan status isCompleted = false
          return Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false, // Di-reset menjadi false
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          );
        }
      }
      // Jika tidak perlu di-reset, kembalikan tugas seperti aslinya
      return task;
    }).toList();
  });
});