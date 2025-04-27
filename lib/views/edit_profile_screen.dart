import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _mbtiController = TextEditingController();
  final _occupationController = TextEditingController();
  final _universityController = TextEditingController();
  final _favoritePlacesController = TextEditingController();
  final _linksController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  String? _imageUrl;
  List<String> _links = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _mbtiController.dispose();
    _occupationController.dispose();
    _universityController.dispose();
    _favoritePlacesController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userData.exists) {
      setState(() {
        _nameController.text = userData.get('username') ?? '';
        _nicknameController.text =
            userData.get('nickname') ?? _nameController.text;
        _bioController.text = userData.get('bio') ?? '';
        _mbtiController.text = userData.get('mbti') ?? '';
        _occupationController.text = userData.get('occupation') ?? '';
        _universityController.text = userData.get('university') ?? '';
        _favoritePlacesController.text = userData.get('favoritePlaces') ?? '';
        _links = List<String>.from(userData.get('links') ?? []);
        _imageUrl = userData.get('photoUrl');
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}_$timestamp.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': user.uid},
      );

      await storageRef.putFile(_imageFile!, metadata);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('画像のアップロードに失敗しました: $e')));
      }
      return null;
    }
  }

  void _addLink() {
    final link = _linksController.text.trim();
    if (link.isNotEmpty) {
      setState(() {
        _links.add(link);
        _linksController.clear();
      });
    }
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? photoUrl = _imageUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage();
      }

      final userData = {
        'username': _nameController.text,
        'nickname': _nicknameController.text,
        'bio': _bioController.text,
        'mbti': _mbtiController.text,
        'occupation': _occupationController.text,
        'university': _universityController.text,
        'favoritePlaces': _favoritePlacesController.text,
        'links': _links,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(userData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('プロフィールを更新しました')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        title: const Text(
          'プロフィール編集',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
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
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0x4000F7FF),
                  foregroundColor: const Color(0xFF1A1B3F),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(
                    color: Color(0xFF00F7FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
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
      ),
      body: Container(
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x8000F7FF),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (_imageUrl != null
                                ? NetworkImage(_imageUrl!) as ImageProvider
                                : const AssetImage(
                                    'assets/default_profile.png')),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00F7FF),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x8000F7FF),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF00F7FF),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1B3F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                labelText: 'ユーザーネーム',
                helperText: '半角英数字と_(アンダースコア)のみ使用可能、16文字以内',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ユーザーネームを入力してください';
                  }
                  if (value.length > 16) {
                    return 'ユーザーネームは16文字以内で入力してください';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return 'ユーザーネームは半角英数字と_のみ使用できます';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nicknameController,
                labelText: 'ニックネーム',
                helperText: '他のユーザーに表示される名前です',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ニックネームを入力してください';
                  }
                  if (value.length > 30) {
                    return 'ニックネームは30文字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                labelText: '自己紹介',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mbtiController,
                labelText: 'MBTI',
                hintText: '例: INTJ',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _occupationController,
                labelText: '職種',
                hintText: '例: 学生、薬剤師、建築家など',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _universityController,
                labelText: '出身・在学大学（任意）',
                hintText: '例: 青森大学',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _favoritePlacesController,
                labelText: '好きなお店・県内企業',
                hintText: '複数ある場合はカンマ(,)で区切って入力',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _linksController,
                      labelText: '外部リンク',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    margin: const EdgeInsets.only(top: 32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00F7FF),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4000F7FF),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF00F7FF),
                      ),
                      onPressed: _addLink,
                    ),
                  ),
                ],
              ),
              if (_links.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B3F).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4000F7FF),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: _links.asMap().entries.map((entry) {
                      return ListTile(
                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Color(0xFF00F7FF),
                          ),
                          onPressed: () => _removeLink(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00F7FF),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? helperText,
    String? hintText,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForField(labelText),
              color: const Color(0xFF00F7FF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              labelText,
              style: const TextStyle(
                color: Color(0xFF00F7FF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00F7FF),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00F7FF),
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            maxLines: maxLines ?? 1,
            validator: validator,
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              helperText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForField(String labelText) {
    switch (labelText) {
      case 'ユーザーネーム':
        return Icons.person;
      case 'ニックネーム':
        return Icons.face;
      case '自己紹介':
        return Icons.description;
      case 'MBTI':
        return Icons.psychology;
      case '職種':
        return Icons.work;
      case '出身・在学大学（任意）':
        return Icons.school;
      case '好きなお店・県内企業':
        return Icons.favorite;
      case '外部リンク':
        return Icons.link;
      default:
        return Icons.edit;
    }
  }
}
