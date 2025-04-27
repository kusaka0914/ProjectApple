import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String title;
  final String eventId;
  final List<String> members;
  final String eventType; // 'event' or 'free_time'
  final Timestamp createdAt;

  ChatRoom({
    required this.id,
    required this.title,
    required this.eventId,
    required this.members,
    required this.eventType,
    required this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      title: data['title'] ?? '',
      eventId: data['eventId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      eventType: data['eventType'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'eventId': eventId,
      'members': members,
      'eventType': eventType,
      'createdAt': createdAt,
    };
  }
}
