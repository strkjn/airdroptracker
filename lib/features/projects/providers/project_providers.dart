// lib/features/projects/providers/project_providers.dart

import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final processedTasksProvider =
    StreamProvider.family<List<Task>, String>((ref, projectId) {
  // 1. Ambil STREAM asli dari provider sumber.
  // Perhatikan penggunaan .stream di akhir. Ini memberikan kita objek Stream,
  // bukan AsyncValue, yang memungkinkan kita untuk me-transform-nya.
  final tasksStream = ref.watch(tasksStreamProvider(projectId).stream);

  // 2. Gunakan .map() dari Stream untuk mengubah setiap list data yang masuk.
  // Riverpod akan secara otomatis menangani state loading dan error dari stream asli.
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
          // Buat instance Task baru dengan isCompleted = false
          // Ini adalah praktik yang baik (immutable state).
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