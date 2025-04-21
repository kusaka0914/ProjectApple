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

    final likeDoc =
        await FirebaseFirestore.instance
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
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);
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
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20.0),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'post_image_${widget.postId}',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
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
                              color: Colors.red,
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
      appBar: AppBar(
        title: const Text('投稿詳細'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _sharePost),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final userName = userData?['displayName'] as String? ?? '不明なユーザー';
          final userPhotoUrl = userData?['photoUrl'] as String?;
          final postCreatedAt = widget.post['createdAt'] as Timestamp?;
          final imageUrl = widget.post['imageUrl'] as String?;
          final caption = widget.post['caption'] as String? ?? '';

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              userPhotoUrl != null
                                  ? NetworkImage(userPhotoUrl)
                                  : const AssetImage(
                                        'assets/default_profile.png',
                                      )
                                      as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (imageUrl != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(imageUrl),
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
                    ],
                    const SizedBox(height: 12),
                    Text(caption),
                    const SizedBox(height: 8),
                    if (postCreatedAt != null)
                      Text(
                        timeago.format(postCreatedAt.toDate(), locale: 'ja'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : null,
                          ),
                          onPressed: _isLoading ? null : _toggleLike,
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .collection('likes')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            final likesCount = snapshot.data?.docs.length ?? 0;
                            return Text('$likesCount件のいいね');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'コメントを追加...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _addComment,
                    ),
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(commentUserId)
                                .get(),
                        builder: (context, userSnapshot) {
                          final commentUserData =
                              userSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                          final commentUserName =
                              commentUserData?['displayName'] as String? ??
                              '不明なユーザー';
                          final commentUserPhotoUrl =
                              commentUserData?['photoUrl'] as String?;

                          final currentUser = FirebaseAuth.instance.currentUser;
                          final isCommentOwner =
                              currentUser?.uid == commentUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  commentUserPhotoUrl != null
                                      ? NetworkImage(commentUserPhotoUrl)
                                      : const AssetImage(
                                            'assets/default_profile.png',
                                          )
                                          as ImageProvider,
                            ),
                            title: Text(commentUserName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(commentText),
                                if (commentCreatedAt != null)
                                  Text(
                                    timeago.format(
                                      commentCreatedAt.toDate(),
                                      locale: 'ja',
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                isCommentOwner
                                    ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed:
                                          () => _deleteComment(
                                            comments[index].id,
                                          ),
                                    )
                                    : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
