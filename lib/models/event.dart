import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final Timestamp date;
  final String imageUrl;
  final String userId;
  final Timestamp createdAt;
  final int participantsCount;
  final List<String> visibleParticipantIds;
  final List<String> participantIds;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    this.participantsCount = 0,
    this.visibleParticipantIds = const [],
    this.participantIds = const [],
    this.location = '',
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] as Timestamp,
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      participantsCount: data['participantsCount'] ?? 0,
      visibleParticipantIds: List<String>.from(
        data['visibleParticipantIds'] ?? [],
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      location: data['location'] ?? '',
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
    };
  }
}
