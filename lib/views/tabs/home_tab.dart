import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../search_result_screen.dart';
import '../tabs/message_tab.dart';

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

  void _showMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: MessageTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1221),
            Color(0xFF1A1B3F),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF1A1B3F),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ユーザーを検索',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF00F7FF),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF00F7FF),
                                    size: 20,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor:
                                    const Color(0xFF1A1B3F).withOpacity(0.5),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
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
                      child: IconButton(
                        icon: const Icon(
                          Icons.message_outlined,
                          color: Color(0xFF00F7FF),
                        ),
                        onPressed: _showMessages,
                        tooltip: 'メッセージ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ... existing feed content ...
        ],
      ),
    );
  }
}
