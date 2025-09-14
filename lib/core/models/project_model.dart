import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus { active, completed, potential }

enum BlockchainNetwork { ethereum, solana, cosmos, other }

class Project {
  final String id;
  final String name;
  final String websiteUrl;
  final ProjectStatus status;
  final BlockchainNetwork blockchainNetwork;
  final String notes;
  final List<String> associatedWalletIds;
  final List<String> associatedSocialAccountIds;

  Project({
    required this.id,
    required this.name,
    this.websiteUrl = '',
    this.status = ProjectStatus.active,
    this.blockchainNetwork = BlockchainNetwork.other,
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
      blockchainNetwork: BlockchainNetwork.values.firstWhere(
        (e) => e.name == data['blockchainNetwork'],
        orElse: () => BlockchainNetwork.other,
      ),
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
      'blockchainNetwork': blockchainNetwork.name,
      'notes': notes,
      'associatedWalletIds': associatedWalletIds,
      'associatedSocialAccountIds': associatedSocialAccountIds,
    };
  }
}
