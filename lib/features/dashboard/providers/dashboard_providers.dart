import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allActiveTasksProvider = StreamProvider<List<Task>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  final projectsStream = firestoreService.getProjects();

  return projectsStream.asyncMap((projects) async {
    final activeProjects = projects
        .where((p) => p.status == ProjectStatus.active)
        .toList();
    if (activeProjects.isEmpty) {
      return [];
    }

    final tasksFutures = activeProjects.map((project) {
      return firestoreService.getTasksForProject(project.id).first;
    }).toList();

    final listOfTaskLists = await Future.wait(tasksFutures);

    return listOfTaskLists.expand((taskList) => taskList).toList();
  });
});

final todaysTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  return allTasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final List<Task> todaysTasks = [];

    for (final task in tasks) {
      bool isDueToday = false;

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

    todaysTasks.sort((a, b) => a.isCompleted ? 1 : -1);

    return todaysTasks;
  });
});
