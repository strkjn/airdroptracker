// lib/core/providers/firebase_providers.dart

import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/services/airdrop_api_service.dart';
import 'package:airdrop_flow/core/services/auth_service.dart';
import 'package:airdrop_flow/core/services/firestore_service.dart';
import 'package:airdrop_flow/core/services/security_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import model notifikasi
import 'package:airdrop_flow/core/models/notification_model.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final airdropApiServiceProvider = Provider<AirdropApiService>((ref) => AirdropApiService());
final securityServiceProvider = Provider<SecurityService>((ref) => SecurityService());

// ======================================================================
// DATA PROVIDERS
// ======================================================================

// ... (semua provider lama Anda tetap di sini) ...
final airdropOpportunitiesProvider = FutureProvider<List<AirdropOpportunity>>((ref) {
  return ref.watch(airdropApiServiceProvider).fetchAirdrops();
});

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjects();
});

final tasksStreamProvider = StreamProvider.family<List<Task>, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTasksForProject(projectId);
});

final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWallets();
});

final socialAccountsStreamProvider = StreamProvider<List<SocialAccount>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSocialAccounts();
});

final taskTemplatesStreamProvider = StreamProvider<List<TaskTemplate>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTaskTemplates();
});

final singleProjectStreamProvider =
    StreamProvider.family<Project, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjectStream(projectId);
});


// --- BARU: Provider untuk Notifikasi ---

/// Menyediakan stream daftar semua notifikasi untuk pengguna saat ini.
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getNotifications();
});

/// Menyediakan stream jumlah notifikasi yang belum dibaca.
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUnreadNotificationsCount();
});