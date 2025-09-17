import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/models/social_account_model.dart';
import 'package:airdrop_flow/core/models/task_model.dart';
import 'package:airdrop_flow/core/models/task_template_model.dart';
import 'package:airdrop_flow/core/models/wallet_model.dart';
import 'package:airdrop_flow/core/services/airdrop_api_service.dart';
import 'package:airdrop_flow/core/services/auth_service.dart';
import 'package:airdrop_flow/core/services/firestore_service.dart';
import 'package:airdrop_flow/core/services/security_service.dart'; // <-- Import baru
import 'package:flutter_riverpod/flutter_riverpod.dart';



final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final airdropApiServiceProvider = Provider<AirdropApiService>((ref) => AirdropApiService());

final securityServiceProvider = Provider<SecurityService>((ref) => SecurityService()); // <-- Provider baru


// ======================================================================
// DATA PROVIDERS
// Provider ini menggunakan Service Provider untuk mengambil dan menyediakan
// data (stream atau future) ke UI.
// ======================================================================

// --- Airdrop Opportunity Providers ---
final airdropOpportunitiesProvider = FutureProvider<List<AirdropOpportunity>>((ref) {
  return ref.watch(airdropApiServiceProvider).fetchAirdrops();
});

// --- Project Providers ---
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjects();
});

// --- Task Providers ---
final tasksStreamProvider = StreamProvider.family<List<Task>, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTasksForProject(projectId);
});

// --- Wallet Providers ---
final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWallets();
});

// --- Social Account Providers ---
final socialAccountsStreamProvider = StreamProvider<List<SocialAccount>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSocialAccounts();
});

// --- Task Template Providers ---
final taskTemplatesStreamProvider = StreamProvider<List<TaskTemplate>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTaskTemplates();
});

final singleProjectStreamProvider =
    StreamProvider.family<Project, String>((ref, projectId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getProjectStream(projectId);
});