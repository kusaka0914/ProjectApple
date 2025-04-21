import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/place.dart';
import '../../models/post.dart';
import '../../providers/service_providers.dart';
import '../../widgets/post_card.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchTypeProvider = StateProvider<SearchType>(
  (ref) => SearchType.places,
);

enum SearchType { places, posts }

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _places = [];
  List<Post> _posts = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchType = ref.read(searchTypeProvider);
      if (searchType == SearchType.places) {
        final placeService = ref.read(placeServiceProvider);
        _places = await placeService.searchPlaces(query);
        _posts = [];
      } else {
        // TODO: 投稿の検索機能を実装
        _places = [];
        _posts = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('検索中にエラーが発生しました: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: searchType == SearchType.places ? '観光スポットを検索' : '投稿を検索',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _places = [];
                  _posts = [];
                });
              },
            ),
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: Column(
        children: [
          _buildSearchTypeSelector(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    final searchType = ref.watch(searchTypeProvider);

    return SegmentedButton<SearchType>(
      segments: const [
        ButtonSegment<SearchType>(
          value: SearchType.places,
          label: Text('スポット'),
          icon: Icon(Icons.place),
        ),
        ButtonSegment<SearchType>(
          value: SearchType.posts,
          label: Text('投稿'),
          icon: Icon(Icons.article),
        ),
      ],
      selected: {searchType},
      onSelectionChanged: (Set<SearchType> newSelection) {
        ref.read(searchTypeProvider.notifier).state = newSelection.first;
      },
    );
  }

  Widget _buildSearchResults() {
    final searchType = ref.watch(searchTypeProvider);

    if (_searchController.text.isEmpty) {
      return const Center(child: Text('検索キーワードを入力してください'));
    }

    if (searchType == SearchType.places) {
      if (_places.isEmpty) {
        return const Center(child: Text('該当する観光スポットが見つかりませんでした'));
      }

      return ListView.builder(
        itemCount: _places.length,
        itemBuilder: (context, index) {
          final place = _places[index];
          return ListTile(
            leading:
                place.images.isNotEmpty
                    ? CircleAvatar(
                      backgroundImage: NetworkImage(place.images.first),
                    )
                    : const CircleAvatar(child: Icon(Icons.place)),
            title: Text(place.name),
            subtitle: Text(
              place.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                Text('${place.rating}'),
              ],
            ),
            onTap: () {
              // TODO: 場所の詳細画面に遷移
            },
          );
        },
      );
    } else {
      if (_posts.isEmpty) {
        return const Center(child: Text('該当する投稿が見つかりませんでした'));
      }

      return ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: _posts[index]);
        },
      );
    }
  }
}
