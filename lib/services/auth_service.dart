import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final UserService _userService;
  User? _currentUser;

  AuthService({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  User? get currentUser => _currentUser;

  Future<void> _updateCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      return;
    }

    final userDoc = await _userService.getUser(firebaseUser.uid);
    _currentUser = userDoc != null ? User.fromFirestore(userDoc) : null;
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _updateCurrentUser();
    return _currentUser;
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final now = DateTime.now();
    final user = User(
      id: credential.user!.uid,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );

    await _userService.createUser(user);
    await _updateCurrentUser();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _userService.deleteUser(user.uid);
      await user.delete();
      _currentUser = null;
    }
  }

  Stream<User?> authStateChanges() async* {
    await for (final _ in _auth.authStateChanges()) {
      await _updateCurrentUser();
      yield _currentUser;
    }
  }

  // メールアドレスとパスワードで登録
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);

        // Firestoreにユーザー情報を保存
        await _userService.createUser(
          User(
            id: credential.user!.uid,
            displayName: displayName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // メールアドレスとパスワードでログイン
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 最終ログイン時刻を更新
      if (credential.user != null) {
        await _userService.updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Firebase Auth のエラーを日本語に変換
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('メールアドレスの形式が正しくありません');
      case 'user-disabled':
        return Exception('このアカウントは無効になっています');
      case 'user-not-found':
        return Exception('アカウントが見つかりません');
      case 'wrong-password':
        return Exception('パスワードが間違っています');
      case 'email-already-in-use':
        return Exception('このメールアドレスは既に使用されています');
      case 'operation-not-allowed':
        return Exception('この操作は許可されていません');
      case 'weak-password':
        return Exception('パスワードが弱すぎます');
      default:
        return Exception('認証エラーが発生しました: ${e.message}');
    }
  }
}
