import 'package:cloud_firestore/cloud_firestore.dart';

enum AirdropDifficulty { Easy, Medium, Hard }

class AirdropOpportunity {
  final String id;
  final String name;
  final String description;
  final String sourceUrl;
  final AirdropDifficulty difficulty;

  AirdropOpportunity({
    required this.id,
    required this.name,
    this.description = '',
    this.sourceUrl = '',
    this.difficulty = AirdropDifficulty.Medium,
  });

  // --- PENTING: Untuk API V2 ---
  // Jika nama field di JSON berubah, Anda hanya perlu mengubahnya di sini.
  // Contoh: jika 'name' menjadi 'airdrop_title', ganti json['name'] menjadi json['airdrop_title'].
  factory AirdropOpportunity.fromJson(Map<String, dynamic> json) {
    return AirdropOpportunity(
      id: json['key'] ?? DateTime.now().toIso8601String(),
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No Description',
      sourceUrl: json['url'] ?? '',
      difficulty: _parseDifficulty(json['difficulty']),
    );
  }

  // Fungsi ini tidak berubah, digunakan untuk data dari Firestore
  factory AirdropOpportunity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return AirdropOpportunity(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sourceUrl: data['sourceUrl'] ?? '',
      difficulty: _parseDifficulty(data['difficulty']),
    );
  }

  static AirdropDifficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return AirdropDifficulty.Easy;
      case 'hard':
        return AirdropDifficulty.Hard;
      default:
        return AirdropDifficulty.Medium;
    }
  }
}