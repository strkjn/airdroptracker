import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskCategory { OneTime, Daily, Weekly }

class Task {
  final String id;
  final String projectId;
  final String name;
  final String taskUrl;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime? lastCompletedTimestamp;

  Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.taskUrl = '',
    required this.category,
    this.isCompleted = false,
    this.lastCompletedTimestamp,
  });

  factory Task.fromFirestore(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  String projectId,
) {
  final data = snapshot.data()!;
  // Perubahan di sini: Mengambil timestamp bisa null
  final timestamp = data['lastCompletedTimestamp'] as Timestamp?;
  return Task(
    id: snapshot.id,
    projectId: projectId,
    name: data['name'] ?? '',
    taskUrl: data['taskUrl'] ?? '',
    category: TaskCategory.values.firstWhere(
      (e) => e.name == data['category'],
      orElse: () => TaskCategory.OneTime,
    ),
    isCompleted: data['isCompleted'] ?? false,
    lastCompletedTimestamp: timestamp?.toDate(), // Gunakan ?.toDate()
  );
}

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'taskUrl': taskUrl,
      'category': category.name,
      'isCompleted': isCompleted,
      'lastCompletedTimestamp': lastCompletedTimestamp != null
          ? Timestamp.fromDate(lastCompletedTimestamp!)
          : null,
    };
  }
}
