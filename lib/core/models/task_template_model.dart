import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:airdrop_flow/core/models/task_model.dart'; // Kita akan menggunakan enum TaskCategory

// Model untuk satu item tugas di dalam template
class TemplateTaskItem {
  final String name;
  final String taskUrl;
  final TaskCategory category;

  TemplateTaskItem({
    required this.name,
    this.taskUrl = '',
    required this.category,
  });

  factory TemplateTaskItem.fromMap(Map<String, dynamic> map) {
    return TemplateTaskItem(
      name: map['name'] ?? '',
      taskUrl: map['taskUrl'] ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.OneTime,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'taskUrl': taskUrl,
      'category': category.name,
    };
  }
}

// Model untuk satu template yang berisi beberapa tugas
class TaskTemplate {
  final String id;
  final String name;
  final String description;
  final List<TemplateTaskItem> tasks;

  TaskTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.tasks,
  });

  factory TaskTemplate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    var taskItems = <TemplateTaskItem>[];
    if (data['tasks'] != null) {
      taskItems = (data['tasks'] as List)
          .map((taskData) => TemplateTaskItem.fromMap(taskData))
          .toList();
    }
    return TaskTemplate(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      tasks: taskItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }
}