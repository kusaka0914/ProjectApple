import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'message_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(widget.user.id)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = doc.exists;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final followingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.user.id);

      final followerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .collection('followers')
          .doc(currentUserId);

      final currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final targetUserRef =
          FirebaseFirestore.instance.collection('users').doc(widget.user.id);

      if (_isFollowing) {
        batch.delete(followingRef);
        batch.delete(followerRef);
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(
            targetUserRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        final now = DateTime.now();
        batch.set(followingRef, {'createdAt': now});
        batch.set(followerRef, {'createdAt': now});
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(1)});
        batch
            .update(targetUserRef, {'followersCount': FieldValue.increment(1)});
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'フォロー解除に失敗しました' : 'フォローに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // 既存のメッセージを検索
      final existingMessage = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', whereIn: [currentUserId, widget.user.id]).where(
              'receiverId',
              whereIn: [currentUserId, widget.user.id]).get();

      String messageId;
      if (existingMessage.docs.isNotEmpty) {
        messageId = existingMessage.docs.first.id;
      } else {
        // 新しいメッセージを作成
        final newMessage =
            await FirebaseFirestore.instance.collection('messages').add({
          'senderId': currentUserId,
          'senderName': FirebaseAuth.instance.currentUser?.displayName ?? '',
          'senderImageUrl': FirebaseAuth.instance.currentUser?.photoURL ?? '',
          'receiverId': widget.user.id,
          'receiverName': widget.user.displayName,
          'receiverImageUrl': widget.user.imageUrl,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': true,
        });
        messageId = newMessage.id;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(messageId: messageId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('チャットの開始に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('ユーザーが見つかりません')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] as String? ?? 'No Name';
        final bio = userData['bio'] as String? ?? '';
        final mbti = userData['mbti'] as String? ?? '';
        final occupation = userData['occupation'] as String? ?? '';
        final university = userData['university'] as String? ?? '';
        final favoritePlaces = userData['favoritePlaces'] as String? ?? '';
        final links = List<String>.from(userData['links'] ?? []);
        final postsCount = userData['postsCount'] as int? ?? 0;
        final followersCount = userData['followersCount'] as int? ?? 0;
        final followingCount = userData['followingCount'] as int? ?? 0;
        final photoUrl = userData['photoUrl'] as String?;

        return Scaffold(
          appBar: AppBar(
            title: Text(displayName),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                      _isFollowing ? Icons.person_remove : Icons.person_add),
                  onPressed: _toggleFollow,
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn('投稿', postsCount),
                                _buildStatColumn('フォロワー', followersCount),
                                _buildStatColumn('フォロー中', followingCount),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(bio),
                          ],
                          if (mbti.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.psychology, size: 16),
                                const SizedBox(width: 4),
                                Text('MBTI: $mbti'),
                              ],
                            ),
                          ],
                          if (occupation.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.work, size: 16),
                                const SizedBox(width: 4),
                                Text('職種: $occupation'),
                              ],
                            ),
                          ],
                          if (university.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.school, size: 16),
                                const SizedBox(width: 4),
                                Text('大学: $university'),
                              ],
                            ),
                          ],
                          if (favoritePlaces.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.favorite, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text('好きなお店・企業: $favoritePlaces'),
                                ),
                              ],
                            ),
                          ],
                          if (links.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.link, size: 16),
                                const SizedBox(width: 4),
                                const Text('外部リンク:'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...links.map(
                              (link) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  bottom: 4,
                                ),
                                child: Text(
                                  link,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.message),
                          label: const Text('メッセージを送る'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 0),
                  ],
                ),
              ),
              _buildPostsGrid(widget.user.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPostsGrid(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('エラーが発生しました: ${snapshot.error}')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '投稿がありません',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final imageUrl = post['imageUrl'] as String?;

              return GestureDetector(
                onTap: () {
                  // TODO: 投稿詳細画面に遷移
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }
}
