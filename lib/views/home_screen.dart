import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tabs/home_tab.dart';
import 'tabs/event_tab.dart';
import 'tabs/job_tab.dart';
import 'tabs/message_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/info_tab.dart';
import 'posts/post_image_picker_screen.dart';
import 'image_picker_screen.dart';
import 'jobs/part_time_job_list_screen.dart';
import 'jobs/create_job_screen.dart';
import 'jobs/create_part_time_job_screen.dart';
import 'info/info_list_screen.dart';
import 'free_time/free_time_event_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedJobType;

  final List<Widget> _tabs = [
    const HomeTab(),
    const EventTab(),
    const JobTab(),
    const InfoTab(),
    const ProfileTab(),
  ];

  void _showJobTypeModal() {
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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F7FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  '案件を探す',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedJobType = 'project';
                    _currentIndex = 2;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.work,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  'アルバイトを探す',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PartTimeJobListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCreateOptionsModal() {
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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F7FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  '投稿を作成',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostImagePickerScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  'イベントを作成',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImagePickerScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  '案件を募集',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateJobScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.work,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  'アルバイトを募集',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePartTimeJobScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showInfoTypeModal() {
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
      {
        'icon': Icons.volunteer_activism,
        'label': 'ボランティア',
        'type': 'volunteer'
      },
      {'icon': Icons.directions_bus, 'label': '交通', 'type': 'transportation'},
      {'icon': Icons.restaurant_menu, 'label': '飲食店', 'type': 'restaurant'},
    ];

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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F7FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InfoListScreen(
                              category: category['label'] as String,
                              type: category['type'] as String,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1B3F),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: const Color(0xFF00F7FF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['label'] as String,
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEventTypeModal() {
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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F7FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  'イベントを探す',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Color(0xFF00F7FF),
                  ),
                ),
                title: const Text(
                  '今ひまを探す',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FreeTimeEventListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
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
            Color(0xFF0B1221),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _tabs[_currentIndex],
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle:
                MaterialStateProperty.resolveWith<TextStyle>((states) {
              final isSelected = states.contains(MaterialState.selected);
              return TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 12,
              );
            }),
            height: 65,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1B3F).withOpacity(0.8),
                  const Color(0xFF0B1221),
                ],
              ),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFF00F7FF),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F7FF).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (index == 2) {
                  _showJobTypeModal();
                } else if (index == 3) {
                  _showInfoTypeModal();
                } else if (index == 1) {
                  _showEventTypeModal();
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                _buildNavDestination(
                  Icons.home_outlined,
                  Icons.home,
                  'ホーム',
                  0,
                ),
                _buildNavDestination(
                  Icons.event_outlined,
                  Icons.event,
                  'イベント',
                  1,
                ),
                _buildNavDestination(
                  Icons.work_outline,
                  Icons.work,
                  '仕事',
                  2,
                ),
                _buildNavDestination(
                  Icons.info_outline,
                  Icons.info,
                  '情報',
                  3,
                ),
                _buildNavDestination(
                  Icons.person_outline,
                  Icons.person,
                  'プロフィール',
                  4,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F7FF).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showCreateOptionsModal,
            backgroundColor: const Color(0xFF1A1B3F),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00F7FF),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF00F7FF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: Icon(
        outlinedIcon,
        color: isSelected
            ? const Color(0xFF00F7FF)
            : const Color(0xFF00F7FF).withOpacity(0.5),
      ),
      selectedIcon: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [
              const Color(0xFF00F7FF),
              const Color(0xFF00F7FF).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Icon(
          filledIcon,
          color: Colors.white,
        ),
      ),
      label: label,
    );
  }
}
