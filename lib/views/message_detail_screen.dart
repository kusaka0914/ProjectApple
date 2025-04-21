import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/message.dart';

class MessageDetailScreen extends StatefulWidget {
  final String messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<DocumentSnapshot>? _subscription;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _startListening();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.messageId)
        .update({'isRead': true});
  }

  void _startListening() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final messageRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.messageId);

    // 3秒のタイムアウトを設定
    Timer(const Duration(seconds: 3), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _subscription?.cancel();
      }
    });

    _subscription = messageRef.snapshots().listen(
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
          print('Error loading message: $error');
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('ログインが必要です');
      }

      final messageDoc =
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(widget.messageId)
              .get();

      if (!messageDoc.exists) {
        throw Exception('メッセージが存在しません');
      }

      final message = Message.fromFirestore(messageDoc);
      final receiverId = message.senderId; // 送信者が次の受信者になる

      // メッセージを追加
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.messageId)
          .collection('chat')
          .add({
            'senderId': currentUserId,
            'message': _messageController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 最後のメッセージを更新
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.messageId)
          .update({
            'lastMessage': _messageController.text,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'isRead': false,
            'receiverId': receiverId,
          });

      _messageController.clear();
    } catch (e) {
      final errorMessage = e is Exception ? e.toString() : 'メッセージの送信に失敗しました';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.messageId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('メッセージが存在しません');
            }
            final message = Message.fromFirestore(snapshot.data!);
            return Text(message.senderName);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'メッセージの読み込みに失敗しました',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('messages')
                    .doc(widget.messageId)
                    .collection('chat')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Error in message detail: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('戻る'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'メッセージを送信してみましょう',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message['senderId'] == currentUserId;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message['message'] as String,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon:
                      _isSending
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
