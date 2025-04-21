import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';

final postServiceProvider = Provider((ref) => PostService());

final postsStreamProvider = StreamProvider<List<Post>>((ref) {
  final postService = ref.watch(postServiceProvider);
  // TODO: フォローしているユーザーのIDリストを取得
  return postService.getPopularPosts();
});

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('青森観光'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 通知画面に遷移
            },
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('投稿がありません'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(postsStreamProvider);
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }
}
