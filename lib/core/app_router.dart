// lib/core/app_router.dart

import 'package:airdrop_flow/features/auth/view/auth_gate.dart';
import 'package:airdrop_flow/features/dashboard/view/main_scaffold.dart';
import 'package:airdrop_flow/features/notifications/view/notification_page.dart';
import 'package:airdrop_flow/features/projects/view/add_edit_project_page.dart';
import 'package:airdrop_flow/features/projects/view/project_detail_page.dart';
import 'package:airdrop_flow/features/socials/view/social_management_page.dart';
import 'package:airdrop_flow/features/wallets/view/wallet_management_page.dart';
import 'package:flutter/material.dart';
import 'package:airdrop_flow/core/models/project_model.dart';

/// Kelas ini mengelola semua logika navigasi dan rute aplikasi.
/// Menggunakan rute yang diberi nama (named routes) membuat kode lebih bersih,
/// lebih mudah dikelola, dan mengurangi risiko error saat mengirim data antar halaman.
class AppRouter {
  // Nama-nama rute (konstanta untuk menghindari kesalahan ketik)
  static const String authGate = '/';
  static const String mainScaffold = '/main';
  static const String projectDetail = '/project-detail';
  static const String addEditProject = '/add-edit-project';
  static const String walletManagement = '/manage-wallets';
  static const String socialManagement = '/manage-socials';
  static const String notification = '/notifications';

  /// Metode ini dipanggil oleh MaterialApp untuk menangani pembuatan rute.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case mainScaffold:
        return MaterialPageRoute(builder: (_) => const MainScaffold());
      case notification:
        return MaterialPageRoute(builder: (_) => const NotificationPage());
      case walletManagement:
        return MaterialPageRoute(builder: (_) => const WalletManagementPage());
      case socialManagement:
        return MaterialPageRoute(builder: (_) => const SocialManagementPage());
      case addEditProject:
        // Jika ada argumen, kita akan membukanya dalam mode edit.
        // Jika tidak, kita membukanya dalam mode tambah baru.
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddEditProjectPage(project: args?['project']),
        );
      case projectDetail:
        // Rute ini WAJIB memiliki argumen 'projectId'.
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProjectDetailPage(projectId: args['projectId']),
        );
      default:
        // Halaman error jika rute tidak ditemukan
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }

  // --- Metode Helper untuk Navigasi yang Type-Safe ---
  // Metode-metode ini menggantikan Navigator.push() yang lama.

  static void goToProjectDetail(BuildContext context, String projectId) {
    Navigator.pushNamed(
      context,
      projectDetail,
      arguments: {'projectId': projectId},
    );
  }

  static void goToAddProject(BuildContext context) {
    Navigator.pushNamed(context, addEditProject);
  }

  static void goToEditProject(BuildContext context, Project project) {
    Navigator.pushNamed(
      context,
      addEditProject,
      arguments: {'project': project},
    );
  }

  static void goToWalletManagement(BuildContext context) {
    Navigator.pushNamed(context, walletManagement);
  }

  static void goToSocialManagement(BuildContext context) {
    Navigator.pushNamed(context, socialManagement);
  }

  static void goToNotifications(BuildContext context) {
    Navigator.pushNamed(context, notification);
  }

  static void goToMainScaffold(BuildContext context) {
    // Menggunakan pushReplacementNamed agar pengguna tidak bisa kembali ke halaman security/login
    Navigator.pushReplacementNamed(context, mainScaffold);
  }
}