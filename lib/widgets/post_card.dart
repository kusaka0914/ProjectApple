import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  post.user.photoUrl != null
                      ? CachedNetworkImageProvider(post.user.photoUrl!)
                      : null,
              child:
                  post.user.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(post.user.displayName),
            subtitle: Text(post.createdAt.toString()),
          ),
          if (post.imageUrl != null)
            CachedNetworkImage(
              imageUrl: post.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) =>
                      const Center(child: Icon(Icons.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(post.content),
              ],
            ),
          ),
          ButtonBar(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // TODO: いいね機能の実装
                },
              ),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  // TODO: コメント機能の実装
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: シェア機能の実装
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
