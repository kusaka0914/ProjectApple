import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String displayName;
  final String profile;
  final String imageUrl;

  AppUser({
    required this.id,
    required this.displayName,
    required this.profile,
    required this.imageUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      profile: data['bio'] as String? ?? '',
      imageUrl: data['photoUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'bio': profile,
      'photoUrl': imageUrl,
    };
  }
}
