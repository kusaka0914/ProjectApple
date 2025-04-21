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

    final userData =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (userData.exists) {
      setState(() {
        _nameController.text = userData.get('displayName') ?? '';
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
        'displayName': _nameController.text,
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
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _saveProfile, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (_imageUrl != null
                                ? NetworkImage(_imageUrl!) as ImageProvider
                                : const AssetImage(
                                  'assets/default_profile.png',
                                )),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザーネーム',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ユーザーネームを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '自己紹介',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mbtiController,
              decoration: const InputDecoration(
                labelText: 'MBTI',
                border: OutlineInputBorder(),
                hintText: '例: INTJ',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: '職種',
                border: OutlineInputBorder(),
                hintText: '例: 学生、薬剤師、建築家など',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(
                labelText: '出身・在学大学（任意）',
                border: OutlineInputBorder(),
                hintText: '例: 青森大学',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _favoritePlacesController,
              decoration: const InputDecoration(
                labelText: '好きなお店・県内企業',
                border: OutlineInputBorder(),
                hintText: '複数ある場合はカンマ(,)で区切って入力',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _linksController,
                    decoration: const InputDecoration(
                      labelText: '外部リンク',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addLink),
              ],
            ),
            if (_links.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children:
                      _links.asMap().entries.map((entry) {
                        return ListTile(
                          title: Text(entry.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeLink(entry.key),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
