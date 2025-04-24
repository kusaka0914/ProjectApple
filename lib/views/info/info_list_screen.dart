import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'info_detail_screen.dart';

class InfoListScreen extends StatelessWidget {
  final String category;
  final String type;

  const InfoListScreen({
    super.key,
    required this.category,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize Japanese locale
    timeago.setLocaleMessages('ja', timeago.JaMessages());

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
          category,
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
              .where('type', isEqualTo: type)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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
                    Text(
                      'エラーが発生しました: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              );
            }

            final posts = snapshot.data?.docs ?? [];

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
                      '$categoryの投稿はまだありません',
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
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;
                final createdAt = (post['createdAt'] as Timestamp).toDate();
                final timeAgo = timeago.format(createdAt, locale: 'ja');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPostCard(
                    context,
                    postId: postId,
                    title: post['title'] as String? ?? '',
                    content: post['content'] as String? ?? '',
                    imageUrl: post['imageUrl'] as String?,
                    userName: post['userName'] as String? ?? '名無しさん',
                    userPhotoUrl: post['userPhotoUrl'] as String?,
                    timeAgo: timeAgo,
                    likes: post['likes'] as int? ?? 0,
                    comments: post['comments'] as int? ?? 0,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
    required String userName,
    String? userPhotoUrl,
    required String timeAgo,
    required int likes,
    required int comments,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoDetailScreen(postId: postId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B3F).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00F7FF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F7FF).withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
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
                          radius: 16,
                          backgroundColor: const Color(0xFF1A1B3F),
                          backgroundImage: userPhotoUrl != null
                              ? NetworkImage(userPhotoUrl)
                              : null,
                          child: userPhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF00F7FF),
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInteractionButton(
                        icon: Icons.favorite_border,
                        count: likes,
                      ),
                      const SizedBox(width: 16),
                      _buildInteractionButton(
                        icon: Icons.chat_bubble_outline,
                        count: comments,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF00F7FF),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Color(0xFF00F7FF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon() {
    switch (type) {
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
}
