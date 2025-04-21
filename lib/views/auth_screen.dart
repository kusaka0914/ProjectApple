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
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    if (!userDoc.exists) {
      // ユーザードキュメントの作成
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.set(userRef, {
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

      // オープンチャットの初期化と参加
      final openChatRef =
          FirebaseFirestore.instance.collection('messages').doc('open_chat');
      final openChatDoc = await openChatRef.get();

      if (!openChatDoc.exists) {
        // オープンチャットが存在しない場合は作成
        batch.set(openChatRef, {
          'id': 'open_chat',
          'type': 'open_chat',
          'title': 'みんなのチャット',
          'description': '全員が参加できるオープンチャットです',
          'lastMessage': '',
          'lastMessageTime': now,
          'isRead': true,
          'participantsCount': 1,
          'participants': [user.uid],
        });

        // 参加メッセージを追加
        final chatRef = openChatRef.collection('chat').doc();
        batch.set(chatRef, {
          'type': 'system',
          'message': '${user.email?.split('@')[0] ?? 'ユーザー'}さんが参加しました',
          'createdAt': now,
        });
      } else {
        // 既存のオープンチャットに参加
        batch.update(openChatRef, {
          'participantsCount': FieldValue.increment(1),
          'participants': FieldValue.arrayUnion([user.uid]),
        });

        // 参加メッセージを追加
        final chatRef = openChatRef.collection('chat').doc();
        batch.set(chatRef, {
          'type': 'system',
          'message': '${user.email?.split('@')[0] ?? 'ユーザー'}さんが参加しました',
          'createdAt': now,
        });
      }

      // バッチ処理を実行
      await batch.commit();
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
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _signIn,
                      child: const Text('ログイン'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signUp,
                      child: const Text('新規登録'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
