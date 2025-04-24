import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'info_detail_screen.dart';

class InfoListScreen extends StatefulWidget {
  final String category;
  final String type;

  const InfoListScreen({
    super.key,
    required this.category,
    required this.type,
  });

  @override
  State<InfoListScreen> createState() => _InfoListScreenState();
}

class _InfoListScreenState extends State<InfoListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 10;
  bool _hasMore = true;
  final Map<String, bool> _isCommentSectionVisible = {};
  final Map<String, bool> _isLiked = {};
  final Map<String, bool> _isLoading = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    timeago.setLocaleMessages('ja', timeago.JaMessages());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: widget.type)
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;
      setState(() {
        _hasMore = snapshot.docs.length == _limit;
      });
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showFullScreenImage(String imageUrl, String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: 'post_image_$postId',
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    final String shareText = '${post['content']}\n\n投稿者: ${post['userName']}';
    Share.share(shareText, subject: 'アプリからの投稿をシェア');
  }

  Future<void> _toggleLike(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading[postId] = true;
    });

    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(currentUser.uid);
      final isCurrentlyLiked = _isLiked[postId] ?? false;

      if (isCurrentlyLiked) {
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await postRef.update({'likesCount': FieldValue.increment(1)});
      }

      setState(() {
        _isLiked[postId] = !isCurrentlyLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('エラーが発生しました')));
    } finally {
      setState(() {
        _isLoading[postId] = false;
      });
    }
  }

  Future<void> _checkIfLiked(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _isLiked[postId] = likeDoc.exists;
      });
    }
  }

  void _showLikesModal(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('likes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F7FF)),
            );
          }

          final likes = snapshot.data?.docs ?? [];

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'いいねしたユーザー',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: likes.isEmpty
                      ? const Center(
                          child: Text(
                            'まだいいねがありません',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: likes.length,
                          itemBuilder: (context, index) {
                            final like =
                                likes[index].data() as Map<String, dynamic>;
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(like['userId'] as String)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const SizedBox();
                                }

                                final userData = userSnapshot.data?.data()
                                    as Map<String, dynamic>?;
                                final userName =
                                    userData?['displayName'] ?? '名無しさん';
                                final userPhotoUrl = userData?['photoUrl'];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF00F7FF),
                                    backgroundImage: userPhotoUrl != null
                                        ? NetworkImage(userPhotoUrl)
                                        : null,
                                    child: userPhotoUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addComment(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final commentController = _commentControllers[postId];
    if (commentController == null) return;

    final comment = commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isLoading[postId] = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': currentUser.uid,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'commentsCount': FieldValue.increment(1)});

      commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('エラーが発生しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[postId] = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return timeago.format(date, locale: 'ja');
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
          widget.category,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('type', isEqualTo: widget.type)
              .orderBy('createdAt', descending: true)
              .limit(_limit)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'エラーが発生しました: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00F7FF)),
              );
            }

            final posts = snapshot.data!.docs;
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 48,
                      color: const Color(0xFF00F7FF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.category}の投稿はまだありません',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return _hasMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF00F7FF),
                            ),
                          ),
                        )
                      : const SizedBox();
                }

                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;
                final userId = post['userId'] as String;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    final userName = userData?['displayName'] ?? '不明なユーザー';
                    final userPhotoUrl = userData?['photoUrl'];
                    final postCreatedAt = post['createdAt'] as Timestamp;
                    final imageUrl = post['imageUrl'] as String?;
                    final content = post['content'] as String? ?? '';
                    final type = post['type'] as String?;
                    final storeName = post['storeName'] as String?;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF00F7FF),
                                  backgroundImage: userPhotoUrl != null
                                      ? NetworkImage(userPhotoUrl)
                                      : null,
                                  child: userPhotoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        timeago.format(postCreatedAt.toDate(),
                                            locale: 'ja'),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Color(0xFF00F7FF),
                                  ),
                                  onPressed: () => _sharePost(post),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (imageUrl != null) ...[
                            GestureDetector(
                              onTap: () =>
                                  _showFullScreenImage(imageUrl, postId),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: const Color(0xFF00F7FF)
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Hero(
                                  tag: 'post_image_$postId',
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (type != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00F7FF)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF00F7FF),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getCategoryLabel(type),
                                          style: const TextStyle(
                                            color: Color(0xFF00F7FF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (type != null && storeName != null)
                                      const SizedBox(width: 8),
                                    if (storeName != null)
                                      Expanded(
                                        child: Text(
                                          storeName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (!(_isLoading[postId] ?? false)) {
                                          _toggleLike(postId);
                                        }
                                      },
                                      child: Icon(
                                        (_isLiked[postId] ?? false)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: (_isLiked[postId] ?? false)
                                            ? Colors.red
                                            : const Color(0xFF00F7FF),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showLikesModal(postId),
                                      child: Text(
                                        '${post['likesCount'] ?? 0}件のいいね',
                                        style: TextStyle(
                                          color: (_isLiked[postId] ?? false)
                                              ? Colors.red
                                              : const Color(0xFF00F7FF),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCommentSectionVisible[postId] =
                                              !(_isCommentSectionVisible[
                                                      postId] ??
                                                  false);
                                        });
                                        if (_commentControllers[postId] ==
                                            null) {
                                          _commentControllers[postId] =
                                              TextEditingController();
                                        }
                                        _checkIfLiked(postId);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            (_isCommentSectionVisible[postId] ??
                                                    false)
                                                ? Icons.comment
                                                : Icons.comment_outlined,
                                            color: const Color(0xFF00F7FF),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${post['commentsCount'] ?? 0}件のコメント',
                                            style: const TextStyle(
                                              color: Color(0xFF00F7FF),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_isCommentSectionVisible[postId] ?? false) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('comments')
                                        .orderBy('createdAt', descending: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF00F7FF),
                                          ),
                                        );
                                      }

                                      final comments =
                                          snapshot.data?.docs ?? [];

                                      if (comments.isEmpty) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: Text(
                                              'コメントはまだありません',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: comments.map((comment) {
                                          final commentData = comment.data()
                                              as Map<String, dynamic>;
                                          final userId =
                                              commentData['userId'] as String;

                                          return FutureBuilder<
                                              DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .get(),
                                            builder: (context, userSnapshot) {
                                              if (!userSnapshot.hasData) {
                                                return const SizedBox();
                                              }

                                              final userData =
                                                  userSnapshot.data!.data()
                                                      as Map<String, dynamic>?;
                                              final userName =
                                                  userData?['displayName'] ??
                                                      '不明なユーザー';
                                              final userPhotoUrl =
                                                  userData?['photoUrl'];

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF00F7FF),
                                                      backgroundImage:
                                                          userPhotoUrl != null
                                                              ? NetworkImage(
                                                                  userPhotoUrl)
                                                              : null,
                                                      child: userPhotoUrl ==
                                                              null
                                                          ? const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            userName,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            commentData[
                                                                    'comment'] ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            _formatTimestamp(
                                                                commentData[
                                                                        'createdAt']
                                                                    as Timestamp),
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white60,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                _commentControllers[postId],
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: 'コメントを追加...',
                                              hintStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6)),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF00F7FF),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF00F7FF),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF00F7FF),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed:
                                              (_isLoading[postId] ?? false)
                                                  ? null
                                                  : () => _addComment(postId),
                                          icon: (_isLoading[postId] ?? false)
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Color(0xFF00F7FF),
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.send,
                                                  color: Color(0xFF00F7FF),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.type) {
      case 'lunch':
        return Icons.restaurant;
      case 'beauty':
        return Icons.spa;
      case 'fashion':
        return Icons.shopping_bag;
      case 'leisure':
        return Icons.sports_esports;
      case 'radio':
        return Icons.radio;
      case 'bar':
        return Icons.local_bar;
      case 'hidden_gem':
        return Icons.store;
      case 'cafe':
        return Icons.local_cafe;
      case 'photo_spot':
        return Icons.camera_alt;
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'transportation':
        return Icons.directions_bus;
      case 'restaurant':
        return Icons.restaurant_menu;
      default:
        return Icons.info_outline;
    }
  }

  String _getCategoryLabel(String type) {
    switch (type) {
      case 'lunch':
        return 'ランチ';
      case 'beauty':
        return '美容';
      case 'fashion':
        return 'ファッション';
      case 'leisure':
        return 'レジャー';
      case 'radio':
        return 'ラジオ';
      case 'bar':
        return '居酒屋・バー';
      case 'hidden_gem':
        return '隠れた名店';
      case 'cafe':
        return 'カフェ';
      case 'photo_spot':
        return '映えスポット';
      case 'volunteer':
        return 'ボランティア';
      case 'transportation':
        return '交通';
      case 'restaurant':
        return '飲食店';
      default:
        return type;
    }
  }
}
