import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _numberOfPeopleController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _deadline;
  String? _selectedCategory;
  List<File> _attachments = [];
  bool _isLoading = false;

  // 仕事カテゴリの選択肢
  final List<Map<String, String>> _categories = [
    {'id': 'web', 'name': 'Webサイト制作'},
    {'id': 'app', 'name': 'アプリ開発'},
    {'id': 'design', 'name': 'デザイン'},
    {'id': 'writing', 'name': '記事作成・ライティング'},
    {'id': 'marketing', 'name': 'マーケティング'},
    {'id': 'video', 'name': '動画編集'},
    {'id': 'photo', 'name': '写真撮影・編集'},
    {'id': 'translation', 'name': '翻訳'},
    {'id': 'other', 'name': 'その他'},
  ];

  // 詳細テンプレート
  final List<Map<String, String>> _templates = [
    {
      'name': 'Webサイト制作',
      'content': '''【依頼の背景】

【制作物の概要】

【必要な機能】

【参考サイト】

【希望するデザインテイスト】

【その他要望】''',
    },
    {
      'name': 'アプリ開発',
      'content': '''【アプリの概要】

【必要な機能】

【対応プラットフォーム】

【技術要件】

【参考アプリ】

【その他要望】''',
    },
    {
      'name': '記事作成',
      'content': '''【記事のテーマ】

【想定読者】

【記事の構成】

【キーワード】

【参考記事】

【その他要望】''',
    },
  ];

  Future<void> _pickFiles() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _attachments.addAll(
          pickedFiles.map((file) => File(file.path)).toList(),
        );
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F7FF),
              onPrimary: Color(0xFF1A1B3F),
              surface: Color(0xFF1A1B3F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _applyTemplate(String template) {
    _detailsController.text = template;
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1B3F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFF00F7FF),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'テンプレートを選択',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _templates.length,
                  (index) => ListTile(
                    title: Text(
                      _templates[index]['name']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      _applyTemplate(_templates[index]['content']!);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリを選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('応募期限を設定してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('ユーザーが見つかりません');

      // ユーザープロフィール情報を取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) throw Exception('ユーザー情報が見つかりません');

      final userData = userDoc.data()!;

      // 添付ファイルをアップロード
      List<String> attachmentUrls = [];
      for (var file in _attachments) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('job_attachments')
            .child(
                '${DateTime.now().millisecondsSinceEpoch}_${attachmentUrls.length}.jpg');
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        attachmentUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('jobs').add({
        'userId': userId,
        'category': _selectedCategory,
        'title': _titleController.text,
        'details': _detailsController.text,
        'numberOfPeople': int.parse(_numberOfPeopleController.text),
        'budget': int.parse(_budgetController.text.replaceAll(',', '')),
        'deadline': Timestamp.fromDate(_deadline!),
        'attachments': attachmentUrls,
        'userName': userData['nickname'] ?? userData['username'] ?? '',
        'userPhotoUrl': userData['photoUrl'],
        'userBio': userData['bio'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('案件を投稿しました'),
            backgroundColor: Color(0xFF00F7FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
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
    _titleController.dispose();
    _detailsController.dispose();
    _numberOfPeopleController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        title: const Text(
          '案件を募集',
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
                onPressed: _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x4000F7FF),
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
                  '作成',
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
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1B3F).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F7FF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'カテゴリ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF00F7FF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((category) {
                                final isSelected =
                                    _selectedCategory == category['id'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category['id'];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF00F7FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF00F7FF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category['name']!,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF1A1B3F)
                                            : const Color(0xFF00F7FF),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleController,
                        labelText: '依頼タイトル',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'タイトルを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '依頼詳細',
                                style: TextStyle(
                                  color: Color(0xFF00F7FF),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _showTemplateDialog,
                                icon: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF00F7FF),
                                  size: 16,
                                ),
                                label: const Text(
                                  'テンプレートを使用',
                                  style: TextStyle(
                                    color: Color(0xFF00F7FF),
                                    fontSize: 14,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _detailsController,
                            labelText: '依頼詳細',
                            maxLines: 10,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '詳細を入力してください';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '添付ファイル',
                                style: TextStyle(
                                  color: Color(0xFF00F7FF),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _pickFiles,
                                icon: const Icon(
                                  Icons.attach_file,
                                  color: Color(0xFF00F7FF),
                                  size: 16,
                                ),
                                label: const Text(
                                  'ファイルを添付',
                                  style: TextStyle(
                                    color: Color(0xFF00F7FF),
                                    fontSize: 14,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: Color(0xFF00F7FF),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_attachments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                _attachments.length,
                                (index) => Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF00F7FF),
                                          width: 1,
                                        ),
                                        image: DecorationImage(
                                          image: FileImage(_attachments[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Color(0xFF00F7FF),
                                        ),
                                        onPressed: () =>
                                            _removeAttachment(index),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _numberOfPeopleController,
                        labelText: '募集人数',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '募集人数を入力してください';
                          }
                          if (int.tryParse(value) == null) {
                            return '有効な数値を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _budgetController,
                        labelText: '予算（円）',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '予算を入力してください';
                          }
                          if (int.tryParse(value.replaceAll(',', '')) == null) {
                            return '有効な数値を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '応募期限',
                            style: TextStyle(
                              color: Color(0xFF00F7FF),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDeadline(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1B3F).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00F7FF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF00F7FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _deadline != null
                                        ? '${_deadline!.year}年${_deadline!.month}月${_deadline!.day}日'
                                        : '応募期限を選択',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int? maxLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
            maxLines: maxLines ?? 1,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '${labelText}を入力してください',
              hintStyle: const TextStyle(color: Colors.white54),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
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
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
