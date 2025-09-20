// lib/core/providers/firebase_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/services/airdrop_api_service.dart';
import 'package:airdrop_flow/core/services/auth_service.dart';
import 'package:airdrop_flow/core/services/firestore_service.dart';
import 'package:airdrop_flow/core/services/security_service.dart';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/notification_model.dart';

final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final securityServiceProvider =
    Provider<SecurityService>((ref) => SecurityService());
final airdropApiServiceProvider =
    Provider<AirdropApiService>((ref) => AirdropApiService());

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjects();
});

final singleProjectStreamProvider =
    StreamProvider.family<Project, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjectById(projectId);
});

final tasksStreamProvider =
    StreamProvider.family<List<Task>, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTasksForProject(projectId);
});

final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWallets();
});

final socialAccountsStreamProvider =
    StreamProvider<List<SocialAccount>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSocialAccounts();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getNotifications();
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUnreadNotificationsCount();
});

/// Provider ini akan secara otomatis memberitahu UI setiap kali
/// status otentikasi pengguna berubah (misalnya, saat login atau logout).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});