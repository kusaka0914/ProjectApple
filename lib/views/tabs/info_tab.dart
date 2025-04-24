import 'package:flutter/material.dart';
import '../info/info_list_screen.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.restaurant, 'label': 'ランチ', 'type': 'lunch'},
    {'icon': Icons.spa, 'label': '美容', 'type': 'beauty'},
    {'icon': Icons.shopping_bag, 'label': 'ファッション', 'type': 'fashion'},
    {'icon': Icons.sports_esports, 'label': 'レジャー', 'type': 'leisure'},
    {'icon': Icons.radio, 'label': 'ラジオ', 'type': 'radio'},
    {'icon': Icons.local_bar, 'label': '居酒屋・バー', 'type': 'bar'},
    {'icon': Icons.store, 'label': '隠れた名店', 'type': 'hidden_gem'},
    {'icon': Icons.local_cafe, 'label': 'カフェ', 'type': 'cafe'},
    {'icon': Icons.camera_alt, 'label': '映えスポット', 'type': 'photo_spot'},
    {'icon': Icons.volunteer_activism, 'label': 'ボランティア', 'type': 'volunteer'},
    {'icon': Icons.directions_bus, 'label': '交通', 'type': 'transportation'},
    {'icon': Icons.restaurant_menu, 'label': '飲食店', 'type': 'restaurant'},
  ];

  void _showCategoryModal(BuildContext context, String label, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1B3F),
                Color(0xFF0B1221),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFF00F7FF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F7FF).withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F7FF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.list_alt,
                  color: Color(0xFF00F7FF),
                ),
                title: Text(
                  '$labelの一覧を見る',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfoListScreen(
                        category: label,
                        type: type,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
            title: const Text(
              '情報',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            floating: true,
            backgroundColor: const Color(0xFF1A1B3F),
            flexibleSpace: Container(
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _categories[index];
                  return _buildCategoryButton(
                    context,
                    icon: category['icon'] as IconData,
                    label: category['label'] as String,
                    type: category['type'] as String,
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _showCategoryModal(context, label, type),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B3F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00F7FF),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F7FF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00F7FF),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
