import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  final String userId;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.post,
    required this.userId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isLoading = false;
  bool _isCommentSectionVisible = false;
  bool _isLoadingMoreComments = false;
  int _commentsLimit = 10;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _isLiked = likeDoc.exists;
      });
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final likeRef = postRef.collection('likes').doc(currentUser.uid);

      if (_isLiked) {
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
        _isLiked = !_isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLikesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
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

  Future<void> _addComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': currentUser.uid,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentsCount': FieldValue.increment(1)});

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    setState(() {
      _isLoadingMoreComments = true;
    });

    try {
      setState(() {
        _commentsLimit += 10;
      });
    } finally {
      setState(() {
        _isLoadingMoreComments = false;
      });
    }
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
        title: const Text(
          '投稿詳細',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share,
              color: Color(0xFF00F7FF),
            ),
            onPressed: _sharePost,
          ),
        ],
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00F7FF)),
              );
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final userName = userData?['displayName'] as String? ?? '不明なユーザー';
            final userPhotoUrl = userData?['photoUrl'] as String?;
            final postCreatedAt = widget.post['createdAt'] as Timestamp?;
            final imageUrl = widget.post['imageUrl'] as String?;
            final content = widget.post['content'] as String? ?? '';
            final type = widget.post['type'] as String?;
            final storeName = widget.post['storeName'] as String?;

            return ListView(
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (postCreatedAt != null)
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (imageUrl != null) ...[
                        GestureDetector(
                          onTap: () => _showFullScreenImage(imageUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Hero(
                              tag: 'post_image_${widget.postId}',
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
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF00F7FF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _categories.firstWhere(
                                        (cat) => cat['type'] == type,
                                        orElse: () =>
                                            {'label': type, 'type': type},
                                      )['label'] as String,
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
                                  onTap: _toggleLike,
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked
                                        ? Colors.red
                                        : const Color(0xFF00F7FF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showLikesModal(),
                                  child: Text(
                                    '${widget.post['likesCount'] ?? 0}件のいいね',
                                    style: TextStyle(
                                      color: _isLiked
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
                                      _isCommentSectionVisible =
                                          !_isCommentSectionVisible;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isCommentSectionVisible
                                            ? Icons.comment
                                            : Icons.comment_outlined,
                                        color: const Color(0xFF00F7FF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.post['commentsCount'] ?? 0}件のコメント',
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
                    ],
                  ),
                ),
                if (_isCommentSectionVisible) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'コメント',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .orderBy('createdAt', descending: true)
                              .limit(_commentsLimit)
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

                            final comments = snapshot.data?.docs ?? [];

                            if (comments.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
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
                              children: [
                                ...comments.map((comment) {
                                  final commentData =
                                      comment.data() as Map<String, dynamic>;
                                  final userId =
                                      commentData['userId'] as String;

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .get(),
                                    builder: (context, userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const SizedBox(height: 50);
                                      }

                                      final userData = userSnapshot.data?.data()
                                          as Map<String, dynamic>?;
                                      final userName =
                                          userData?['displayName'] ?? '不明なユーザー';
                                      final userPhotoUrl =
                                          userData?['photoUrl'];

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  const Color(0xFF00F7FF),
                                              backgroundImage: userPhotoUrl !=
                                                      null
                                                  ? NetworkImage(userPhotoUrl)
                                                  : null,
                                              child: userPhotoUrl == null
                                                  ? const Icon(Icons.person,
                                                      color: Colors.white,
                                                      size: 20)
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    commentData['comment'] ??
                                                        '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatTimestamp(
                                                        commentData['createdAt']
                                                            as Timestamp),
                                                    style: const TextStyle(
                                                      color: Colors.white60,
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
                                }),
                                if (widget.post['commentsCount'] >
                                    _commentsLimit)
                                  TextButton(
                                    onPressed: _loadMoreComments,
                                    child: _isLoadingMoreComments
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF00F7FF),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'さらに読み込む',
                                            style: TextStyle(
                                              color: Color(0xFF00F7FF),
                                            ),
                                          ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'コメントを追加...',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _isLoading ? null : _addComment,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: 'post_image_${widget.postId}',
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

  void _sharePost() {
    final String shareText =
        '${widget.post['content']}\n\n投稿者: ${widget.post['userName']}';
    Share.share(shareText, subject: 'アプリからの投稿をシェア');
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return timeago.format(date, locale: 'ja');
  }
}

final List<Map<String, dynamic>> _categories = const [
  {'icon': Icons.restaurant, 'label': 'ランチ', 'type': 'lunch'},
  {'icon': Icons.spa, 'label': '美容', 'type': 'beauty'},
  {'icon': Icons.shopping_bag, 'label': 'ファッション', 'type': 'fashion'},
  {'icon': Icons.sports_esports, 'label': 'レジャー', 'type': 'leisure'},
  {'icon': Icons.radio, 'label': 'ラジオ', 'type': 'radio'},
  {'icon': Icons.local_bar, 'label': '居酒屋・バー', 'type': 'bar'},
  {'icon': Icons.store, 'label': '隠れた名店', 'type': 'hidden_gem'},
  {'icon': Icons.local_cafe, 'label': 'カフェ', 'type': 'cafe'},
  {'icon': Icons.camera_alt, 'label': '映えスポット', 'type': 'photo_spot'},
  {'icon': Icons.volunteer_activism, 'label': 'ボランティア', 'type': 'volunteer'},
  {'icon': Icons.directions_bus, 'label': '交通', 'type': 'transportation'},
  {'icon': Icons.restaurant_menu, 'label': '飲食店', 'type': 'restaurant'},
];
