import 'dart:async';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final todaysTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final allTasksAsync = ref.watch(allActiveTasksProvider);

  return allTasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final resetTime = DateTime(now.year, now.month, now.day, 7);
    
    final List<Task> todaysTasks = [];

    bool isTaskDueForReset(Task task) {
      if (!task.isCompleted || task.lastCompletedTimestamp == null) {
        return false; 
      }
      
      final lastCompleted = task.lastCompletedTimestamp!;
      
      if (now.isAfter(resetTime)) {
        return lastCompleted.isBefore(resetTime);
      } else {
        final yesterdayResetTime = resetTime.subtract(const Duration(days: 1));
        return lastCompleted.isBefore(yesterdayResetTime);
      }
    }

    for (final task in tasks) {
      bool isTodaysTask = false;
      bool isReset = isTaskDueForReset(task);

      switch (task.category) {
        case TaskCategory.OneTime:
          if (!task.isCompleted) {
            isTodaysTask = true;
          }
          break;
        case TaskCategory.Daily:
        case TaskCategory.Weekly:
          isTodaysTask = true;
          break;
      }
      
      if (isTodaysTask) {
        if (isReset) {
          todaysTasks.add(Task(
            id: task.id,
            projectId: task.projectId,
            name: task.name,
            taskUrl: task.taskUrl,
            category: task.category,
            isCompleted: false, 
            lastCompletedTimestamp: task.lastCompletedTimestamp,
          ));
        } else {
          todaysTasks.add(task);
        }
      }
    }

    todaysTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });

    return todaysTasks;
  });
});