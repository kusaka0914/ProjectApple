import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'message_detail_screen.dart';
import 'follow_list_screen.dart';
import 'post_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

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
        .doc(widget.userId)
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
          .doc(widget.userId);

      final followerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUserId);

      final currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final targetUserRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'フォロー解除に失敗しました' : 'フォローに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('ログインが必要です');
      }

      // 自分自身とのチャットを防ぐ
      if (currentUserId == widget.userId) {
        throw Exception('自分自身とチャットを開始することはできません');
      }

      // participants配列を使用して既存のメッセージを検索
      final existingMessages = await FirebaseFirestore.instance
          .collection('messages')
          .where('participants',
              arrayContainsAny: [currentUserId, widget.userId]).get();

      String? messageId;
      // 両方のユーザーを含むチャットルームを探す
      for (var doc in existingMessages.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        if (participants.contains(currentUserId) &&
            participants.contains(widget.userId)) {
          messageId = doc.id;
          break;
        }
      }

      if (messageId == null) {
        // 新しいメッセージを作成
        final currentUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        final targetUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        if (!currentUser.exists || !targetUser.exists) {
          throw Exception('ユーザー情報が見つかりません');
        }

        final currentUserData = currentUser.data() as Map<String, dynamic>;
        final targetUserData = targetUser.data() as Map<String, dynamic>;

        final newMessageRef =
            FirebaseFirestore.instance.collection('messages').doc();
        await newMessageRef.set({
          'participants': [currentUserId, widget.userId],
          'participantDetails': {
            currentUserId: {
              'id': currentUserId,
              'displayName': currentUserData['nickname'] ??
                  currentUserData['username'] ??
                  '',
              'photoUrl': currentUserData['photoUrl'] ?? '',
            },
            widget.userId: {
              'id': widget.userId,
              'displayName': targetUserData['nickname'] ??
                  targetUserData['username'] ??
                  '',
              'photoUrl': targetUserData['photoUrl'] ?? '',
            },
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'private',
        });
        messageId = newMessageRef.id;

        // チャットサブコレクションに初期メッセージを作成
        // await newMessageRef.collection('chat').add({
        //   'senderId': 'system',
        //   'message': 'チャットが開始されました',
        //   'createdAt': FieldValue.serverTimestamp(),
        //   'type': 'system',
        // });
      }

      if (mounted && messageId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(messageId: messageId!),
          ),
        );
      }
    } catch (e) {
      print('Error in _startChat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1221),
                    Color(0xFF1A1B3F),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1221),
                    Color(0xFF1A1B3F),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'ユーザーが見つかりません',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] as String? ?? 'No Name';
        final nickname = userData['nickname'] as String? ?? username;
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
          backgroundColor: Colors.transparent,
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
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF00F7FF),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF00F7FF),
                                Color(0xFF0B1221),
                              ],
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black, Colors.transparent],
                              ).createShader(
                                  Rect.fromLTRB(0, 0, rect.width, rect.height));
                            },
                            blendMode: BlendMode.dstIn,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.blue, Colors.purple],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x8000F7FF),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 45, color: Color(0xFF00F7FF))
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF00F7FF),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color: Color(0xFF00F7FF),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1B3F).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF00F7FF),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4000F7FF),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('投稿', postsCount),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF00F7FF).withOpacity(0.3),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowListScreen(
                                        userId: widget.userId,
                                        isFollowers: true,
                                      ),
                                    ),
                                  );
                                },
                                child:
                                    _buildStatColumn('フォロワー', followersCount),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFF00F7FF).withOpacity(0.3),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowListScreen(
                                        userId: widget.userId,
                                        isFollowers: false,
                                      ),
                                    ),
                                  );
                                },
                                child:
                                    _buildStatColumn('フォロー中', followingCount),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1B3F).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF00F7FF),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4000F7FF),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bio.isNotEmpty) ...[
                                Text(
                                  bio,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 15),
                              ],
                              Row(
                                children: [
                                  if (mbti.isNotEmpty)
                                    Expanded(
                                      child: _buildProfileItem(
                                          Icons.psychology, 'MBTI', mbti),
                                    ),
                                  const SizedBox(width: 20),
                                  if (occupation.isNotEmpty)
                                    Expanded(
                                      child: _buildProfileItem(
                                          Icons.work, '職種', occupation),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (university.isNotEmpty)
                                    Expanded(
                                      child: _buildProfileItem(
                                          Icons.school, '大学', university),
                                    ),
                                  const SizedBox(width: 20),
                                  if (favoritePlaces.isNotEmpty)
                                    Expanded(
                                      child: _buildProfileItem(Icons.favorite,
                                          '好きなお店・企業', favoritePlaces),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F7FF)
                                          .withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _toggleFollow,
                                  icon: Icon(
                                    _isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                    color: _isFollowing
                                        ? Colors.white70
                                        : const Color(0xFF00F7FF),
                                  ),
                                  label: Text(
                                    _isFollowing ? 'フォロー中' : 'フォローする',
                                    style: TextStyle(
                                      color: _isFollowing
                                          ? Colors.white70
                                          : const Color(0xFF00F7FF),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _isFollowing
                                          ? Colors.white30
                                          : const Color(0xFF00F7FF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F7FF)
                                          .withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _startChat,
                                  icon: const Icon(
                                    Icons.message,
                                    color: Color(0xFF00F7FF),
                                  ),
                                  label: const Text(
                                    'メッセージ',
                                    style: TextStyle(
                                      color: Color(0xFF00F7FF),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildPostsGrid(widget.userId),
              ],
            ),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00F7FF),
            shadows: [
              Shadow(
                color: Color(0x8000F7FF),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF00F7FF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF00F7FF),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            child: Center(
              child: Text(
                'エラーが発生しました: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00F7FF),
              ),
            ),
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
                      color: Color(0xFF00F7FF),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '投稿がありません',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final imageUrl = post['imageUrl'] as String?;
                final caption = post['caption'] as String?;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          postId: posts[index].id,
                          post: post,
                          userId: post['userId'] as String,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF00F7FF),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4000F7FF),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFF00F7FF),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Color(0xFF00F7FF),
                                    size: 32,
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              color: const Color(0xFF1A1B3F),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Color(0xFF00F7FF),
                                  size: 32,
                                ),
                              ),
                            ),
                          if (caption != null && caption.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }
}
