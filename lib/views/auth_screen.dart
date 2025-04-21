import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserData(User user) async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userDoc.exists) {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'displayName': user.email?.split('@')[0] ?? 'ユーザー',
        'email': user.email,
        'photoUrl': null,
        'bio': '',
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (credential.user != null) {
        await _initializeUserData(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '予期せぬエラーが発生しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (credential.user != null) {
        await _initializeUserData(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '予期せぬエラーが発生しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
        return 'アカウントが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      default:
        return '認証エラーが発生しました';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('ログイン')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '青森県の観光情報アプリへようこそ！',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('ログイン'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _signUp,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('新規登録'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
