import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final String receiverId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl = '',
    required this.receiverId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderImageUrl: data['senderImageUrl'] ?? '',
      receiverId: data['receiverId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'receiverId': receiverId,
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
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      receiverId: receiverId ?? this.receiverId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isRead: isRead ?? this.isRead,
    );
  }
}
