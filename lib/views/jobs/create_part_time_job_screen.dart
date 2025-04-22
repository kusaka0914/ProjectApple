import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePartTimeJobScreen extends StatefulWidget {
  const CreatePartTimeJobScreen({super.key});

  @override
  State<CreatePartTimeJobScreen> createState() =>
      _CreatePartTimeJobScreenState();
}

class _CreatePartTimeJobScreenState extends State<CreatePartTimeJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hourlyWageController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _workingDaysController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _applyUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

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

      await FirebaseFirestore.instance.collection('partTimeJobs').add({
        'userId': userId,
        'title': _titleController.text,
        'hourlyWage': int.parse(_hourlyWageController.text.replaceAll(',', '')),
        'location': _locationController.text,
        'address': _addressController.text,
        'workingHours': _workingHoursController.text,
        'workingDays': _workingDaysController.text,
        'description': _descriptionController.text,
        'requirements': _requirementsController.text,
        'benefits': _benefitsController.text,
        'userName': userData['nickname'] ?? userData['username'] ?? '',
        'userPhotoUrl': userData['photoUrl'],
        'userBio': userData['bio'] ?? '',
        'applyUrl': _applyUrlController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アルバイトを投稿しました'),
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
    _hourlyWageController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    _workingDaysController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _applyUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            SliverAppBar(
              backgroundColor: const Color(0xFF1A1B3F),
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF00F7FF),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'アルバイトを募集',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        labelText: 'アルバイトタイトル',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'タイトルを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _hourlyWageController,
                        labelText: '時給（円）',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '時給を入力してください';
                          }
                          if (int.tryParse(value.replaceAll(',', '')) == null) {
                            return '有効な数値を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _locationController,
                        labelText: '勤務地（エリア）',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '勤務地を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        labelText: '勤務地（住所）',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '住所を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _workingHoursController,
                        labelText: '勤務時間',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '勤務時間を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _workingDaysController,
                        labelText: '勤務日',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '勤務日を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        labelText: '仕事内容',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '仕事内容を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _requirementsController,
                        labelText: '応募資格',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '応募資格を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _benefitsController,
                        labelText: '待遇・福利厚生',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '待遇・福利厚生を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _applyUrlController,
                        labelText: '応募URL',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '応募URLを入力してください';
                          }
                          final uri = Uri.tryParse(value);
                          if (uri == null ||
                              (!uri.hasScheme || !uri.hasAuthority)) {
                            return '有効なURLを入力してください';
                          }
                          return null;
                        },
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B3F),
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
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F7FF),
              foregroundColor: const Color(0xFF1A1B3F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A1B3F),
                      ),
                    ),
                  )
                : const Text(
                    '投稿する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF00F7FF)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00F7FF),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00F7FF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1B3F).withOpacity(0.5),
      ),
    );
  }
}
