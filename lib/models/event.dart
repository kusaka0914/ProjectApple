import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;
  final int participantsCount;
  final List<String> participantIds;
  final List<String> visibleParticipantIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
    required this.participantsCount,
    required this.participantIds,
    required this.visibleParticipantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      organizerId: data['organizerId'] ?? '',
      participantsCount: data['participantsCount'] ?? 0,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      visibleParticipantIds: List<String>.from(
        data['visibleParticipantIds'] ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'organizerId': organizerId,
      'participantsCount': participantsCount,
      'participantIds': participantIds,
      'visibleParticipantIds': visibleParticipantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
