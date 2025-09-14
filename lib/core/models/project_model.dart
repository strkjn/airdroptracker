// lib/core/models/project_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum ProjectStatus tetap ada
enum ProjectStatus { active, completed, potential }

// Enum BlockchainNetwork kita hapus karena akan diganti dengan input teks

class Project {
  final String id;
  final String name;
  final String websiteUrl;
  final ProjectStatus status;
  // --- PERUBAHAN: Tipe data diubah dari enum menjadi String ---
  final String blockchainNetwork;
  final String notes;
  final List<String> associatedWalletIds;
  final List<String> associatedSocialAccountIds;

  Project({
    required this.id,
    required this.name,
    this.websiteUrl = '',
    this.status = ProjectStatus.active,
    // --- PERUBAHAN: Nilai default diubah menjadi string kosong ---
    this.blockchainNetwork = '',
    this.notes = '',
    this.associatedWalletIds = const [],
    this.associatedSocialAccountIds = const [],
  });

  factory Project.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Project(
      id: snapshot.id,
      name: data['name'] ?? '',
      websiteUrl: data['websiteUrl'] ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProjectStatus.active,
      ),
      // --- PERUBAHAN: Membaca langsung sebagai String ---
      blockchainNetwork: data['blockchainNetwork'] ?? '',
      notes: data['notes'] ?? '',
      associatedWalletIds: List<String>.from(data['associatedWalletIds'] ?? []),
      associatedSocialAccountIds: List<String>.from(
        data['associatedSocialAccountIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'websiteUrl': websiteUrl,
      'status': status.name,
      // --- PERUBAHAN: Menyimpan langsung sebagai String ---
      'blockchainNetwork': blockchainNetwork,
      'notes': notes,
      'associatedWalletIds': associatedWalletIds,
      'associatedSocialAccountIds': associatedSocialAccountIds,
    };
  }
}