import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String profile;
  final String imageUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.profile,
    required this.imageUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? '',
      profile: data['profile'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'profile': profile, 'imageUrl': imageUrl};
  }
}
