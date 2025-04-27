import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 公式イベント用グループチャットを作成
  Future<String> createOfficialEventChat({
    required String eventId,
    required String title,
    required String organizerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    // チャットルームを作成
    final chatRef = await _firestore.collection('event_chats').add({
      'eventId': eventId,
      'title': title,
      'type': 'official',
      'organizerId': organizerId,
      'members': [organizerId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'イベントのグループチャットが作成されました',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': organizerId,
      'unreadCount': 0,
      'participantDetails': {
        organizerId: await _getUserDetails(organizerId),
      },
    });

    // イベントにチャットIDを紐付け
    await _firestore.collection('events').doc(eventId).update({
      'chatId': chatRef.id,
    });

    return chatRef.id;
  }

  // 今暇イベント用グループチャットを作成
  Future<String> createFreeTimeEventChat({
    required String eventId,
    required String title,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    // ユーザー情報を取得
    final userDetails = await _getUserDetails(user.uid);

    // チャットルームを作成
    final chatRef = await _firestore.collection('event_chats').add({
      'eventId': eventId,
      'title': title,
      'type': 'free_time',
      'members': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'グループを作成しました',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': user.uid,
      'unreadCount': 0,
      'participantDetails': {
        user.uid: userDetails,
      },
    });

    // イベントにチャットIDを紐付け
    await _firestore.collection('free_time_events').doc(eventId).update({
      'chatId': chatRef.id,
    });

    return chatRef.id;
  }

  // イベントチャットにメッセージを送信
  Future<void> sendEventMessage({
    required String chatId,
    required String message,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    final batch = _firestore.batch();

    // メッセージを追加
    final messageRef = _firestore
        .collection('event_chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': user.uid,
      'message': message,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 最終メッセージを更新
    final chatRef = _firestore.collection('event_chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': user.uid,
    });

    await batch.commit();
  }

  // イベントチャットの取得
  Stream<DocumentSnapshot> getEventChat(String chatId) {
    return _firestore.collection('event_chats').doc(chatId).snapshots();
  }

  // イベントチャットのメッセージ一覧を取得
  Stream<QuerySnapshot> getEventMessages(String chatId) {
    return _firestore
        .collection('event_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // イベントチャットに参加
  Future<void> joinEventChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    // ユーザー情報を取得
    final userDetails = await _getUserDetails(user.uid);

    final batch = _firestore.batch();
    final chatRef = _firestore.collection('event_chats').doc(chatId);

    batch.update(chatRef, {
      'members': FieldValue.arrayUnion([user.uid]),
      'participantDetails.${user.uid}': userDetails,
    });

    await batch.commit();
  }

  // イベントチャットから退出
  Future<void> leaveEventChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    final batch = _firestore.batch();
    final chatRef = _firestore.collection('event_chats').doc(chatId);

    batch.update(chatRef, {
      'members': FieldValue.arrayRemove([user.uid]),
      'participantDetails.${user.uid}': FieldValue.delete(),
    });

    await batch.commit();
  }

  // ユーザー情報を取得
  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    return {
      'displayName': userData['displayName'] ?? '名無しさん',
      'photoURL': userData['photoUrl'] ?? '',
      'lastRead': FieldValue.serverTimestamp(),
    };
  }
}
