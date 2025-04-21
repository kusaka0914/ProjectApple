import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    return doc.exists ? doc : null;
  }

  Future<void> createUser(User user) async {
    await _users.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateUser({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (bio != null) data['bio'] = bio;

    await _users.doc(userId).update(data);
  }

  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  Future<void> updateLastLogin(String userId) async {
    await _users.doc(userId).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
