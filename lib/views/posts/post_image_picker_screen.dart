import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'post_create_screen.dart';

class PostImagePickerScreen extends StatefulWidget {
  const PostImagePickerScreen({super.key});

  @override
  PostImagePickerScreenState createState() => PostImagePickerScreenState();
}

class PostImagePickerScreenState extends State<PostImagePickerScreen> {
  File? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostCreateScreen(imageFile: _imageFile!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規投稿')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('投稿する写真を選択してください', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, size: 36),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const Text('ギャラリーから選択'),
                ],
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt, size: 36),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const Text('カメラで撮影'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
