import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../providers/providers.dart';

final userPostsProvider = StreamProvider.autoDispose<List<Post>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final postService = ref.watch(postServiceProvider);
  final currentUser = authService.currentUser;
  if (currentUser == null) return Stream.value([]);
  return postService.getUserPosts(currentUser.id);
});

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;
    final userPosts = ref.watch(userPostsProvider);

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ログインが必要です'),
            ElevatedButton(
              onPressed: () {
                // TODO: ログイン画面に遷移
              },
              child: const Text('ログイン'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 設定画面に遷移
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(userPostsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          currentUser.photoUrl != null
                              ? NetworkImage(currentUser.photoUrl!)
                              : null,
                      child:
                          currentUser.photoUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (currentUser.bio != null) ...[
                      const SizedBox(height: 8),
                      Text(currentUser.bio!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(context, '投稿', '0'),
                        _buildStatColumn(context, 'フォロワー', '0'),
                        _buildStatColumn(context, 'フォロー中', '0'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        // TODO: プロフィール編集画面に遷移
                      },
                      child: const Text('プロフィールを編集'),
                    ),
                  ],
                ),
              ),
            ),
            userPosts.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('投稿がありません')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(post: posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
              loading:
                  () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, stackTrace) => SliverFillRemaining(
                    child: Center(child: Text('エラーが発生しました: $error')),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
      ],
    );
  }
}
