import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../edit_profile_screen.dart';
import '../post_detail_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../auth_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<String?> _getLocalImagePath(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_$userId.jpg');
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return null;
  }

  Future<void> _createUserProfile(String userId) async {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'id': userId,
      'displayName': user.email?.split('@')[0] ?? 'ユーザー',
      'email': user.email,
      'photoUrl': null,
      'bio': '',
      'mbti': '',
      'favoritePlaces': '',
      'links': [],
      'postsCount': 0,
      'followersCount': 0,
      'followingCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ログアウト'),
            content: const Text('ログアウトしてもよろしいですか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログアウトに失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('ログアウト'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('ログインしてください'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          _createUserProfile(user.uid);
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] as String? ?? 'No Name';
        final bio = userData['bio'] as String? ?? '';
        final mbti = userData['mbti'] as String? ?? '';
        final favoritePlaces = userData['favoritePlaces'] as String? ?? '';
        final links = List<String>.from(userData['links'] ?? []);
        final postsCount = userData['postsCount'] as int? ?? 0;
        final followersCount = userData['followersCount'] as int? ?? 0;
        final followingCount = userData['followingCount'] as int? ?? 0;
        final photoUrl = userData['photoUrl'] as String?;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('プロフィール'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsMenu(context),
                ),
              ],
            ),
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
                          backgroundImage:
                              photoUrl != null
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : const AssetImage(
                                    'assets/default_profile.png',
                                  ),
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
                              child: GestureDetector(
                                onTap: () => _launchURL(link),
                                child: Text(
                                  link,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
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
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('プロフィールを編集'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 0),
                ],
              ),
            ),
            _buildPostsGrid(user.uid),
          ],
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
      stream:
          FirebaseFirestore.instance
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
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final imageUrl = post['imageUrl'] as String?;
            final caption = post['caption'] as String?;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PostDetailScreen(
                          postId: posts[index].id,
                          post: post,
                          userId: post['userId'] as String,
                        ),
                  ),
                );
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
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
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
          }, childCount: posts.length),
        );
      },
    );
  }
}
