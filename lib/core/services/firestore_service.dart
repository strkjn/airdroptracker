// lib/core/services/firestore_service.dart

import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import model yang baru kita buat
import 'package:airdrop_flow/core/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _userCollection(String collectionName) {
    final userId = _userId;
    if (userId == null) throw Exception("Pengguna tidak login!");
    return _db.collection('users').doc(userId).collection(collectionName);
  }

  // --- Metode Proyek, Tugas, Wallet, dll. tidak berubah ---
  // ... (semua kode lama Anda dari addProject hingga applyTemplateToProject tetap di sini) ...
  Future<void> addProject(Project project) async {
    await _userCollection('projects').add(project.toJson());
  }

  Future<void> updateProject(Project project) async {
    await _userCollection('projects').doc(project.id).update(project.toJson());
  }

  Future<void> deleteProject(String projectId) async {
    final tasksSnapshot = await _userCollection('projects').doc(projectId).collection('tasks').get();
    
    final batch = _db.batch();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _userCollection('projects').doc(projectId).delete();
  }

  Stream<List<Project>> getProjects() {
    if (_userId == null) return Stream.value([]);
    return _userCollection('projects').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    });
  }
  
  Future<Project?> getProjectById(String projectId) async {
    if (_userId == null) return null;
    final doc = await _userCollection('projects').doc(projectId).get();
    if (doc.exists) {
      return Project.fromFirestore(doc);
    }
    return null;
  }
  Stream<Project> getProjectStream(String projectId) {
  if (_userId == null) return Stream.error("User not logged in!");
  final docRef = _userCollection('projects').doc(projectId);
  return docRef.snapshots().map((doc) {
    if (!doc.exists) {
      throw Exception('Proyek tidak ditemukan');
    }
    return Project.fromFirestore(doc);
  });
}

  Future<void> addTaskToProject({
    required String projectId,
    required String taskName,
    required TaskCategory category,
  }) async {
    final newTask = Task(id: '', projectId: projectId, name: taskName, category: category);
    await _userCollection('projects').doc(projectId).collection('tasks').add(newTask.toJson());
  }

  Stream<List<Task>> getTasksForProject(String projectId) {
    if (_userId == null) return Stream.value([]);
    return _userCollection('projects').doc(projectId).collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc, projectId)).toList();
    });
  }

  Future<void> updateTaskStatus({
    required String projectId,
    required String taskId,
    required bool isCompleted,
  }) async {
    await _userCollection('projects').doc(projectId).collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
      'lastCompletedTimestamp': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteTask({
    required String projectId,
    required String taskId,
  }) async {
    await _userCollection('projects').doc(projectId).collection('tasks').doc(taskId).delete();
  }

  Future<void> addWallet(Wallet wallet) async {
    await _userCollection('wallets').add(wallet.toJson());
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _userCollection('wallets').doc(wallet.id).update(wallet.toJson());
  }

  Future<void> deleteWallet(String walletId) async {
    await _userCollection('wallets').doc(walletId).delete();
  }

  Stream<List<Wallet>> getWallets() {
    if (_userId == null) return Stream.value([]);
    return _userCollection('wallets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Wallet.fromFirestore(doc)).toList();
    });
  }

  Future<void> addSocialAccount(SocialAccount account) async {
    await _userCollection('social_accounts').add(account.toJson());
  }

  Future<void> updateSocialAccount(SocialAccount account) async {
    await _userCollection('social_accounts').doc(account.id).update(account.toJson());
  }

  Future<void> deleteSocialAccount(String accountId) async {
    await _userCollection('social_accounts').doc(accountId).delete();
  }

  Stream<List<SocialAccount>> getSocialAccounts() {
    if (_userId == null) return Stream.value([]);
    return _userCollection('social_accounts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SocialAccount.fromFirestore(doc)).toList();
    });
  }

  // --- BARU: Metode untuk Notifikasi ---

  /// Menambahkan notifikasi baru untuk pengguna.
  Future<void> addNotification(String title, String body) async {
    if (_userId == null) return;
    final newNotification = NotificationModel(
      id: '',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await _userCollection('notifications').add(newNotification.toJson());
  }

  /// Mendapatkan stream daftar notifikasi, diurutkan dari yang terbaru.
  Stream<List<NotificationModel>> getNotifications() {
    if (_userId == null) return Stream.value([]);
    return _userCollection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }

  /// Menandai satu notifikasi sebagai sudah dibaca.
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_userId == null) return;
    await _userCollection('notifications').doc(notificationId).update({'isRead': true});
  }

  /// Mendapatkan stream untuk jumlah notifikasi yang belum dibaca.
  Stream<int> getUnreadNotificationsCount() {
    if (_userId == null) return Stream.value(0);
    return _userCollection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}