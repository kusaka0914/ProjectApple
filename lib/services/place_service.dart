import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 場所を追加
  Future<String> addPlace(Place place) async {
    final docRef = await _firestore
        .collection('places')
        .add(place.toFirestore());
    return docRef.id;
  }

  // 場所を更新
  Future<void> updatePlace(Place place) async {
    await _firestore
        .collection('places')
        .doc(place.id)
        .update(place.toFirestore());
  }

  // 場所を削除
  Future<void> deletePlace(String placeId) async {
    await _firestore.collection('places').doc(placeId).delete();
  }

  // 場所を取得
  Future<Place?> getPlace(String placeId) async {
    final doc = await _firestore.collection('places').doc(placeId).get();
    if (doc.exists) {
      return Place.fromFirestore(doc);
    }
    return null;
  }

  // 場所を検索（カテゴリー別）
  Stream<List<Place>> getPlacesByCategory(String category) {
    return _firestore
        .collection('places')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList(),
        );
  }

  // 人気の場所を取得
  Stream<List<Place>> getPopularPlaces({int limit = 10}) {
    return _firestore
        .collection('places')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList(),
        );
  }

  // キーワードで場所を検索
  Future<List<Place>> searchPlaces(String keyword) async {
    final snapshot =
        await _firestore
            .collection('places')
            .where('name', isGreaterThanOrEqualTo: keyword)
            .where('name', isLessThanOrEqualTo: keyword + '\uf8ff')
            .get();

    return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
  }
}
