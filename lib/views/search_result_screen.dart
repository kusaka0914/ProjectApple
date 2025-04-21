import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'message_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultScreen({super.key, required this.searchQuery});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _searchUsers();
  }

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: widget.searchQuery)
              .where('name', isLessThan: widget.searchQuery + '\uf8ff')
              .get();

      final users =
          querySnapshot.docs
              .map((doc) => AppUser.fromFirestore(doc))
              .where((user) => user.id != currentUserId)
              .toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat(AppUser user) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // 既存のメッセージを検索
      final existingMessage =
          await FirebaseFirestore.instance
              .collection('messages')
              .where('senderId', whereIn: [currentUserId, user.id])
              .where('receiverId', whereIn: [currentUserId, user.id])
              .get();

      String messageId;
      if (existingMessage.docs.isNotEmpty) {
        messageId = existingMessage.docs.first.id;
      } else {
        // 新しいメッセージを作成
        final newMessage = await FirebaseFirestore.instance
            .collection('messages')
            .add({
              'senderId': currentUserId,
              'senderName':
                  FirebaseAuth.instance.currentUser?.displayName ?? '',
              'senderImageUrl':
                  FirebaseAuth.instance.currentUser?.photoURL ?? '',
              'receiverId': user.id,
              'receiverName': user.name,
              'receiverImageUrl': user.imageUrl,
              'lastMessage': '',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'isRead': true,
            });
        messageId = newMessage.id;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(messageId: messageId),
          ),
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('チャットの開始に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('「${widget.searchQuery}」の検索結果')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'ユーザーの検索に失敗しました',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ユーザーが見つかりませんでした',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
            child: user.imageUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.name),
          subtitle: Text(user.profile),
          trailing: IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => _startChat(user),
          ),
        );
      },
    );
  }
}
