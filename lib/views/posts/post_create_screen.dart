import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostCreateScreen extends StatefulWidget {
  final File imageFile;

  const PostCreateScreen({super.key, required this.imageFile});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;

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

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿内容を入力してください')),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // 画像をStorageにアップロード
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'posts/${user.uid}/$timestamp.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(
        widget.imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final imageUrl = await ref.getDownloadURL();

      // Firestoreに投稿を保存
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': userData['displayName'] ?? '名無しさん',
        'userPhotoUrl': userData['photoUrl'],
        'content': _contentController.text.trim(),
        'storeName': _storeNameController.text.trim(),
        'type': _selectedType,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿が完了しました')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        title: const Text(
          '新規投稿',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00F7FF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F7FF).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: _submitPost,
                icon: const Icon(
                  Icons.send,
                  color: Color(0xFF00F7FF),
                ),
                label: const Text(
                  '投稿',
                  style: TextStyle(
                    color: Color(0xFF00F7FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F7FF).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(widget.imageFile, fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'カテゴリ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedType == category['type'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = isSelected
                                  ? null
                                  : category['type'] as String;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00F7FF)
                                  : const Color(0xFF1A1B3F),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F7FF)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF00F7FF),
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF00F7FF),
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
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contentController,
                      labelText: '投稿内容',
                      hintText: '投稿の内容を入力してください',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _storeNameController,
                      labelText: '店舗名（任意）',
                      hintText: '店舗名を入力してください',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B3F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00F7FF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F7FF).withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: -4,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines ?? 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
