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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentsCount': FieldValue.increment(-1)});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('コメントを削除しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('コメントの削除に失敗しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0B1221),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close,
                color: Color(0xFF00F7FF),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20.0),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'post_image_${widget.postId}',
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF00F7FF),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Color(0xFF00F7FF),
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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
        '${widget.post['caption']}\n\n投稿者: ${widget.post['username']}';
    Share.share(shareText, subject: 'アプリからの投稿をシェア');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '投稿詳細',
          style: TextStyle(
            color: Color(0xFF00F7FF),
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
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              );
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final userName = userData?['displayName'] as String? ?? '不明なユーザー';
            final userPhotoUrl = userData?['photoUrl'] as String?;
            final postCreatedAt = widget.post['createdAt'] as Timestamp?;
            final imageUrl = widget.post['imageUrl'] as String?;
            final caption = widget.post['caption'] as String? ?? '';

            return ListView(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00F7FF),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x8000F7FF),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: userPhotoUrl != null
                                    ? NetworkImage(userPhotoUrl)
                                    : const AssetImage(
                                            'assets/default_profile.png')
                                        as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (postCreatedAt != null)
                              Text(
                                timeago.format(postCreatedAt.toDate(),
                                    locale: 'ja'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked
                                        ? Colors.red
                                        : const Color(0xFF00F7FF),
                                  ),
                                  onPressed: _isLoading ? null : _toggleLike,
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .collection('likes')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final likesCount =
                                        snapshot.data?.docs.length ?? 0;
                                    return Text(
                                      '$likesCount件のいいね',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B3F).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'コメントを追加...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color(0xFF00F7FF),
                        ),
                        onPressed: _isLoading ? null : _addComment,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00F7FF),
                        ),
                      );
                    }

                    final comments = snapshot.data?.docs ?? [];

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment =
                            comments[index].data() as Map<String, dynamic>;
                        final commentUserId = comment['userId'] as String;
                        final commentText = comment['comment'] as String;
                        final commentCreatedAt =
                            comment['createdAt'] as Timestamp?;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(commentUserId)
                              .get(),
                          builder: (context, userSnapshot) {
                            final commentUserData = userSnapshot.data?.data()
                                as Map<String, dynamic>?;
                            final commentUserName =
                                commentUserData?['displayName'] as String? ??
                                    '不明なユーザー';
                            final commentUserPhotoUrl =
                                commentUserData?['photoUrl'] as String?;

                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final isCommentOwner =
                                currentUser?.uid == commentUserId;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1B3F).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00F7FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundImage: commentUserPhotoUrl != null
                                        ? NetworkImage(commentUserPhotoUrl)
                                        : const AssetImage(
                                            'assets/default_profile.png',
                                          ) as ImageProvider,
                                  ),
                                ),
                                title: Text(
                                  commentUserName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      commentText,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (commentCreatedAt != null)
                                      Text(
                                        timeago.format(
                                          commentCreatedAt.toDate(),
                                          locale: 'ja',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: isCommentOwner
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFF00F7FF),
                                        ),
                                        onPressed: () =>
                                            _deleteComment(comments[index].id),
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
