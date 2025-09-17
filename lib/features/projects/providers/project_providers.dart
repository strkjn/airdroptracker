import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz; // Pastikan untuk mengimpor timezone

final processedTasksProvider =
    StreamProvider.family<List<Task>, String>((ref, projectId) {
      
  // 1. Dapatkan stream tugas asli untuk proyek spesifik ini
  final tasksStream = ref.watch(tasksStreamProvider(projectId).stream);

  // 2. Gunakan .map() untuk mengubah setiap daftar tugas yang masuk dari stream
  return tasksStream.map((tasks) {
    // Tentukan zona waktu lokal
    final location = tz.local;
    
    // Dapatkan waktu saat ini di zona waktu lokal
    final now = tz.TZDateTime.now(location);
    
    // Tentukan waktu reset hari ini (jam 7 pagi)
    final todaysResetTime = tz.TZDateTime(location, now.year, now.month, now.day, 7);

    // Tentukan awal "Hari Operasional"
    final startOfDashboardDay = now.isBefore(todaysResetTime)
        ? todaysResetTime.subtract(const Duration(days: 1))
        : todaysResetTime;

    // Proses setiap tugas untuk memeriksa apakah perlu di-reset
    final processedTasks = tasks.map((task) {
      bool needsReset = false;

      if (task.isCompleted && task.lastCompletedTimestamp != null) {
        final lastCompletedLocal = tz.TZDateTime.from(task.lastCompletedTimestamp!, location);

        if (lastCompletedLocal.isBefore(startOfDashboardDay)) {
          if (task.category == TaskCategory.Daily) {
            needsReset = true;
          } else if (task.category == TaskCategory.Weekly) {
            if (now.difference(lastCompletedLocal).inDays >= 7) {
              needsReset = true;
            }
          }
        }
      }

      if (needsReset) {
        // Kembalikan tugas versi baru yang sudah di-reset
        return Task(
          id: task.id,
          projectId: task.projectId,
          name: task.name,
          taskUrl: task.taskUrl,
          category: task.category,
          isCompleted: false, // Di-reset
          lastCompletedTimestamp: task.lastCompletedTimestamp,
        );
      }
      // Jika tidak perlu di-reset, kembalikan tugas aslinya
      return task;
    }).toList();

    // Urutkan daftar agar yang belum selesai ada di atas
     processedTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return processedTasks;
  });
});