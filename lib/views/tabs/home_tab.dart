import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../search_result_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(searchQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ユーザーを検索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ... existing feed content ...
      ],
    );
  }
}
