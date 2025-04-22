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
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPost() async {
    if (_postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投稿内容を入力してください')));
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
        'text': _postController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('投稿が完了しました')));
        Navigator.of(context).popUntil((route) => route.isFirst);
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
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        // title: const Text(
        //   '新規投稿',
        //   style: TextStyle(color: Colors.white),
        // ),
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
              child: IconButton(
                onPressed: _submitPost,
                icon: const Icon(
                  Icons.send,
                  color: Color(0xFF00F7FF),
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
            children: [
              Container(
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
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
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
                  controller: _postController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '投稿内容を入力してください',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
