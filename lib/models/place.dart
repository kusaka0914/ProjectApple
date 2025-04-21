import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final String address;
  final List<String> images;
  final String category;
  final Map<String, dynamic> businessHours;
  final String? website;
  final String? phone;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.images,
    required this.category,
    required this.businessHours,
    this.website,
    this.phone,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Place.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Place(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? '',
      businessHours: Map<String, dynamic>.from(data['businessHours'] ?? {}),
      website: data['website'],
      phone: data['phone'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      amenities: Map<String, dynamic>.from(data['amenities'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'images': images,
      'category': category,
      'businessHours': businessHours,
      'website': website,
      'phone': phone,
      'rating': rating,
      'reviewCount': reviewCount,
      'amenities': amenities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
