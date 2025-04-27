import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String userId;
  final String title;
  final String description;
  final Timestamp date;
  final String imageUrl;
  final Timestamp createdAt;
  final int participantsCount;
  final List<String> visibleParticipantIds;
  final List<String> participantIds;
  final String location;
  final int maxParticipants;

  Event({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.createdAt,
    this.participantsCount = 0,
    this.visibleParticipantIds = const [],
    this.participantIds = const [],
    this.location = '',
    this.maxParticipants = 0,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] as Timestamp,
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      participantsCount: data['participantsCount'] ?? 0,
      visibleParticipantIds:
          List<String>.from(data['visibleParticipantIds'] ?? []),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      location: data['location'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
      'participantsCount': participantsCount,
      'visibleParticipantIds': visibleParticipantIds,
      'participantIds': participantIds,
      'location': location,
      'maxParticipants': maxParticipants,
    };
  }
}
