import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final String receiverId;
  final String receiverName;
  final String receiverImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isRead;
  final String type;
  final String lastMessageSenderId;
  final int unreadCount;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl = '',
    required this.receiverId,
    required this.receiverName,
    this.receiverImageUrl = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.isRead = false,
    required this.type,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final type = data['type'] as String? ?? 'private';
    final participants = List<String>.from(data['participants'] ?? []);
    final participantDetails =
        Map<String, dynamic>.from(data['participantDetails'] ?? {});

    String senderId = '';
    String senderName = '';
    String senderImageUrl = '';
    String receiverId = '';
    String receiverName = '';
    String receiverImageUrl = '';

    if (type == 'private') {
      // 自分以外の参加者の情報を取得
      final otherParticipantId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (data['lastMessageSenderId'] == currentUserId) {
        // 自分が最後のメッセージの送信者の場合
        senderId = currentUserId ?? '';
        final currentUserDetails = participantDetails[currentUserId];
        senderName = currentUserDetails?['displayName'] ?? 'Unknown';
        senderImageUrl = currentUserDetails?['photoURL'] ?? '';

        receiverId = otherParticipantId;
        final otherUserDetails = participantDetails[otherParticipantId];
        receiverName = otherUserDetails?['displayName'] ?? 'Unknown';
        receiverImageUrl = otherUserDetails?['photoURL'] ?? '';
      } else {
        // 相手が最後のメッセージの送信者の場合
        senderId = otherParticipantId;
        final otherUserDetails = participantDetails[otherParticipantId];
        senderName = otherUserDetails?['displayName'] ?? 'Unknown';
        senderImageUrl = otherUserDetails?['photoURL'] ?? '';

        receiverId = currentUserId ?? '';
        final currentUserDetails = participantDetails[currentUserId];
        receiverName = currentUserDetails?['displayName'] ?? 'Unknown';
        receiverImageUrl = currentUserDetails?['photoURL'] ?? '';
      }
    }

    return Message(
      id: doc.id,
      type: type,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
      senderId: senderId,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImageUrl: receiverImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverImageUrl': receiverImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'isRead': isRead,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    String? receiverId,
    String? receiverName,
    String? receiverImageUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isRead,
    String? type,
    String? lastMessageSenderId,
    int? unreadCount,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverImageUrl: receiverImageUrl ?? this.receiverImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
