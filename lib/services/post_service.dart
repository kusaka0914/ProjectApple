import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post.dart';
import '../models/user.dart';
import 'user_service.dart';

class PostService {
  final FirebaseFirestore _firestore;
  final UserService _userService;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  PostService({FirebaseFirestore? firestore, UserService? userService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userService = userService ?? UserService();

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  // ユーザーの投稿を取得
  Stream<List<Post>> getUserPosts(String userId) async* {
    final userDoc = await _userService.getUser(userId);
    if (userDoc == null) {
      yield [];
      return;
    }

    final user = User.fromFirestore(userDoc);
    await for (final snapshot
        in _posts
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final posts = <Post>[];
      for (final doc in snapshot.docs) {
        final post = await Post.fromFirestore(doc);
        if (post != null) {
          posts.add(post);
        }
      }
      yield posts;
    }
  }

  // 投稿を作成
  Future<void> createPost({
    required String userId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final now = DateTime.now();
    await _posts.add({
      'userId': userId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // 投稿を更新
  Future<void> updatePost({
    required String postId,
    String? title,
    String? content,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    await _posts.doc(postId).update(data);
  }

  // 投稿を削除
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  // 投稿を取得
  Future<Post?> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final userDoc = await _userService.getUser(data['userId'] as String);
    if (userDoc == null) return null;

    final user = User.fromFirestore(userDoc);
    return Post.fromFirestore(doc);
  }

  // 場所に関する投稿を取得
  Stream<List<Post>> getPlacePosts(String placeId) async* {
    await for (final snapshot
        in _firestore
            .collection('posts')
            .where('placeId', isEqualTo: placeId)
            .orderBy('createdAt', descending: true)
            .snapshots()) {
      final posts = <Post>[];
      for (final doc in snapshot.docs) {
        final post = await Post.fromFirestore(doc);
        if (post != null) {
          posts.add(post);
        }
      }
      yield posts;
    }
  }

  // タイムライン用の投稿を取得（フォローしているユーザーの投稿）
  Stream<List<Post>> getTimelinePosts(List<String> followingIds) async* {
    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    await for (final snapshot
        in _firestore
            .collection('posts')
            .where('userId', whereIn: followingIds)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()) {
      final posts = <Post>[];
      for (final doc in snapshot.docs) {
        final post = await Post.fromFirestore(doc);
        if (post != null) {
          posts.add(post);
        }
      }
      yield posts;
    }
  }

  // 人気の投稿を取得
  Stream<List<Post>> getPopularPosts({int limit = 20}) async* {
    final snapshot =
        await _firestore
            .collection('posts')
            .orderBy('likeCount', descending: true)
            .limit(limit)
            .get();

    final posts = <Post>[];
    for (final doc in snapshot.docs) {
      try {
        final post = await Post.fromFirestore(doc);
        if (post != null) {
          posts.add(post);
        }
      } catch (e) {
        print('Error loading post: ${doc.id} - $e');
      }
    }

    yield posts;
  }

  // いいねを追加/削除
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final postDoc = await transaction.get(postRef);
      final currentLikes = postDoc.data()?['likeCount'] ?? 0;

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likeCount': currentLikes - 1});
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likeCount': currentLikes + 1});
      }
    });
  }

  // コメントを追加
  Future<void> addComment(String postId, String userId, String content) async {
    final commentRef =
        _firestore.collection('posts').doc(postId).collection('comments').doc();

    await _firestore.runTransaction((transaction) async {
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await transaction.get(postRef);
      final currentComments = postDoc.data()?['commentCount'] ?? 0;

      transaction.set(commentRef, {
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'commentCount': currentComments + 1});
    });
  }

  // コメントを取得
  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }
}
