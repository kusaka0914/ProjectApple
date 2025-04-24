import 'package:cloud_firestore/cloud_firestore.dart';

class FreeTimeEvent {
  final String id;
  final String userId;
  final String title;
  final String type;
  final Timestamp date;
  final int maxParticipants;
  final int? budget;
  final String location;
  final String description;
  final List<String> participants;
  final Timestamp createdAt;

  FreeTimeEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.date,
    required this.maxParticipants,
    this.budget,
    required this.location,
    required this.description,
    required this.participants,
    required this.createdAt,
  });

  factory FreeTimeEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FreeTimeEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      type: data['type'] ?? 'その他',
      date: data['date'] as Timestamp,
      maxParticipants: data['maxParticipants'] ?? 1,
      budget: data['budget'],
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'type': type,
      'date': date,
      'maxParticipants': maxParticipants,
      'budget': budget,
      'location': location,
      'description': description,
      'participants': participants,
      'createdAt': createdAt,
    };
  }
}
