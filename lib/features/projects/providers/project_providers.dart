import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final processedTasksProvider = Provider.family<AsyncValue<List<Task>>, String>((
  ref,
  projectId,
) {
  final asyncTasks = ref.watch(tasksStreamProvider(projectId));

  return asyncTasks.whenData((tasks) {
    final now = DateTime.now();

    return tasks.map((task) {
      bool isStillCompleted = task.isCompleted;

      if (isStillCompleted && task.lastCompletedTimestamp != null) {
        if (task.category == TaskCategory.Daily) {
          if (now.difference(task.lastCompletedTimestamp!).inHours >= 24) {
            isStillCompleted = false;
          }
        } else if (task.category == TaskCategory.Weekly) {
          if (now.difference(task.lastCompletedTimestamp!).inDays >= 7) {
            isStillCompleted = false;
          }
        }
      }

      if (!isStillCompleted && task.isCompleted) {
        return Task(
          id: task.id,
          projectId: task.projectId,
          name: task.name,
          taskUrl: task.taskUrl,
          category: task.category,
          isCompleted: false,
          lastCompletedTimestamp: task.lastCompletedTimestamp,
        );
      }

      return task;
    }).toList();
  });
});
