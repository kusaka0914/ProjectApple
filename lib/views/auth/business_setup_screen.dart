import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/business_category.dart';
import 'welcome_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  BusinessCategory _selectedCategory = BusinessCategory.it;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが見つかりません');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _usernameController.text.trim(),
        'accountType': 'business',
        'businessCategory': _selectedCategory.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '設定の保存に失敗しました';
      });
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
        title: const Text('企業アカウント設定'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'アカウント情報を設定してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<BusinessCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '業種',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: BusinessCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ユーザーネーム',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _completeSetup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('設定を完了する'),
            ),
          ],
        ),
      ),
    );
  }
}
