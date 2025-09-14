import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialPlatform { Twitter, Discord, Telegram }

class SocialAccount {
  final String id;
  final SocialPlatform platform;
  final String username;

  SocialAccount({
    required this.id,
    required this.platform,
    required this.username,
  });

  factory SocialAccount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return SocialAccount(
      id: snapshot.id,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == data['platform'],
        orElse: () => SocialPlatform.Twitter,
      ),
      username: data['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'platform': platform.name, 'username': username};
  }
}
