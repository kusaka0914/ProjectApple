import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/message.dart';
import '../message_detail_screen.dart';

class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  State<MessageTab> createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<QuerySnapshot>? _subscription;
  final String openChatId = 'open_chat'; // オープンチャット用の固定ID

  @override
  void initState() {
    super.initState();
    _startListening();
    _ensureOpenChatExists();
  }

  // オープンチャットのドキュメントが存在することを確認
  Future<void> _ensureOpenChatExists() async {
    final openChatRef =
        FirebaseFirestore.instance.collection('messages').doc(openChatId);
    final doc = await openChatRef.get();

    if (!doc.exists) {
      await openChatRef.set({
        'id': openChatId,
        'type': 'open_chat',
        'title': 'みんなのチャット',
        'description': '全員が参加できるオープンチャットです',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isRead': true,
        'participantsCount': 0,
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // 3秒のタイムアウトを設定
    Timer(const Duration(seconds: 3), () {
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _subscription?.cancel();
      }
    });

    _subscription = FirebaseFirestore.instance
        .collection('messages')
        .where(
          Filter.or(
            Filter.and(
              Filter('senderId', isEqualTo: currentUserId),
              Filter('lastMessage', isNotEqualTo: ''),
            ),
            Filter.and(
              Filter('receiverId', isEqualTo: currentUserId),
              Filter('lastMessage', isNotEqualTo: ''),
            ),
          ),
        )
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          print('Error in message tab: $error');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('ログインが必要です'));
    }

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('メッセージ'), floating: true),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasError)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'メッセージの読み込みに失敗しました',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startListening,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.groups),
                  ),
                  title: const Text('みんなのチャット'),
                  subtitle: const Text('全員が参加できるオープンチャットです'),
                  trailing: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .doc(openChatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox.shrink();

                      final lastMessageTime =
                          (data['lastMessageTime'] as Timestamp?)?.toDate();
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              _formatDateTime(lastMessageTime),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageDetailScreen(
                          messageId: openChatId,
                          isOpenChat: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        // 既存のメッセージリスト
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where(
                Filter.or(
                  Filter.and(
                    Filter('senderId', isEqualTo: currentUserId),
                    Filter('lastMessage', isNotEqualTo: ''),
                  ),
                  Filter.and(
                    Filter('receiverId', isEqualTo: currentUserId),
                    Filter('lastMessage', isNotEqualTo: ''),
                  ),
                ),
              )
              .where('type', isNotEqualTo: 'open_chat') // オープンチャット以外のメッセージを取得
              .orderBy('type', descending: true) // type フィールドのorderByを追加
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text('エラーが発生しました: ${snapshot.error}')),
              );
            }

            final messages = snapshot.data?.docs
                    .map((doc) => Message.fromFirestore(doc))
                    .toList() ??
                [];

            if (messages.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'プライベートメッセージはまだありません',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'メッセージを送信して会話を始めましょう',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final message = messages[index];
                  return MessageListTile(message: message);
                },
                childCount: messages.length,
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

class MessageListTile extends StatelessWidget {
  final Message message;

  const MessageListTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: message.senderImageUrl.isNotEmpty
            ? NetworkImage(message.senderImageUrl)
            : null,
        child: message.senderImageUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(message.senderName),
      subtitle: Text(
        message.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDateTime(message.lastMessageTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (!message.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(messageId: message.id),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
