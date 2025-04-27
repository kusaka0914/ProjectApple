import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'message_detail_screen.dart';
import 'user_profile_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultScreen({super.key, required this.searchQuery});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<AppUser> _users = [];
  final Map<String, bool> _followStatus = {};
  final Map<String, bool> _loadingStatus = {};

  @override
  void initState() {
    super.initState();
    _searchUsers();
  }

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // 検索クエリを小文字に変換
      final lowercaseQuery = widget.searchQuery.toLowerCase();

      // displayNameフィールドで検索
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('displayName', isLessThan: lowercaseQuery + '\uf8ff')
          .get();

      final users = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) => user.id != currentUserId)
          .toList();

      // フォロー状態を確認
      for (final user in users) {
        final isFollowing = await _checkFollowStatus(user.id);
        _followStatus[user.id] = isFollowing;
        _loadingStatus[user.id] = false;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkFollowStatus(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(userId)
        .get();

    return doc.exists;
  }

  Future<void> _toggleFollow(AppUser user) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _loadingStatus[user.id] = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final followingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(user.id);

      final followerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('followers')
          .doc(currentUserId);

      final currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);

      final targetUserRef =
          FirebaseFirestore.instance.collection('users').doc(user.id);

      final isFollowing = _followStatus[user.id] ?? false;

      if (isFollowing) {
        // フォロー解除
        batch.delete(followingRef);
        batch.delete(followerRef);
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(
            targetUserRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        // フォロー
        final now = DateTime.now();
        batch.set(followingRef, {
          'createdAt': now,
        });
        batch.set(followerRef, {
          'createdAt': now,
        });
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(1)});
        batch
            .update(targetUserRef, {'followersCount': FieldValue.increment(1)});
      }

      await batch.commit();

      setState(() {
        _followStatus[user.id] = !isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _followStatus[user.id] ?? false ? 'フォロー解除に失敗しました' : 'フォローに失敗しました',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loadingStatus[user.id] = false);
    }
  }

  void _showUserProfile(AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00F7FF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '「${widget.searchQuery}」の検索結果',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: const Border(
                bottom: BorderSide(
                  color: Color(0xFF00F7FF),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F7FF).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1221),
              Color(0xFF1A1B3F),
              Color(0xFF0B1221),
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00F7FF),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFF00F7FF),
            ),
            const SizedBox(height: 16),
            const Text(
              'ユーザーの検索に失敗しました',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchUsers,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                '再試行',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F7FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Color(0xFF00F7FF),
            ),
            SizedBox(height: 16),
            Text(
              'ユーザーが見つかりませんでした',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isFollowing = _followStatus[user.id] ?? false;
        final isLoading = _loadingStatus[user.id] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00F7FF),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F7FF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1A1B3F),
                backgroundImage: user.imageUrl.isNotEmpty
                    ? NetworkImage(user.imageUrl)
                    : null,
                child: user.imageUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF00F7FF),
                      )
                    : null,
              ),
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              user.profile,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00F7FF),
                      strokeWidth: 2,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F7FF).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _toggleFollow(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.transparent
                            : const Color(0xFF00F7FF),
                        foregroundColor: isFollowing
                            ? const Color(0xFF00F7FF)
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: const Color(0xFF00F7FF),
                            width: isFollowing ? 1 : 0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'フォロー中' : 'フォロー',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isFollowing
                              ? const Color(0xFF00F7FF)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
            onTap: () => _showUserProfile(user),
          ),
        );
      },
    );
  }
}
