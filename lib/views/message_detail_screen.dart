import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/message.dart';

class MessageDetailScreen extends StatefulWidget {
  final String messageId;
  final bool isOpenChat;

  const MessageDetailScreen({
    super.key,
    required this.messageId,
    this.isOpenChat = false,
  });

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
    if (!widget.isOpenChat) {
      _markAsRead();
    }
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

    final messageRef =
        FirebaseFirestore.instance.collection('messages').doc(widget.messageId);

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

      final messageDoc = await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('メッセージが存在しません');
      }

      final data = messageDoc.data() as Map<String, dynamic>;

      // オープンチャットの場合
      if (widget.isOpenChat) {
        final currentUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (!currentUser.exists) {
          throw Exception('ユーザー情報が見つかりません');
        }

        final userData = currentUser.data() as Map<String, dynamic>;

        // メッセージを追加
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.messageId)
            .collection('chat')
            .add({
          'senderId': currentUserId,
          'senderName': userData['displayName'] ?? 'Unknown',
          'senderImageUrl': userData['photoUrl'] ?? '',
          'message': _messageController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'message',
        });

        // 最後のメッセージを更新
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.messageId)
            .update({
          'lastMessage': _messageController.text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': true,
        });
      } else {
        // プライベートチャットの場合
        final participantDetails =
            data['participantDetails'] as Map<String, dynamic>?;
        if (participantDetails == null) {
          throw Exception('参加者情報が見つかりません');
        }

        final currentUserDetails =
            participantDetails[currentUserId] as Map<String, dynamic>?;
        if (currentUserDetails == null) {
          throw Exception('送信者情報が見つかりません');
        }

        // メッセージを追加
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.messageId)
            .collection('chat')
            .add({
          'senderId': currentUserId,
          'senderName': currentUserDetails['displayName'],
          'senderImageUrl': currentUserDetails['photoUrl'] ?? '',
          'message': _messageController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'message',
        });

        // 最後のメッセージを更新
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.messageId)
            .update({
          'lastMessage': _messageController.text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
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
      return Scaffold(
        backgroundColor: const Color(0xFF0B1221),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1B3F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF00F7FF),
            ),
            onPressed: () => Navigator.pop(context),
          ),
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
                Color(0xFF0B1221),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'ログインが必要です',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00F7FF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.isOpenChat
            ? const Text(
                'みんなのチャット',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(widget.messageId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'メッセージが存在しません',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  final message = Message.fromFirestore(snapshot.data!);
                  final displayName = message.senderId == currentUserId
                      ? message.receiverName
                      : message.senderName;
                  return Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
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
              Color(0xFF0B1221),
            ],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00F7FF),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFF00F7FF),
              ),
              const SizedBox(height: 16),
              const Text(
                'メッセージの読み込みに失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text(
                  '再読み込み',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F7FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
            stream: FirebaseFirestore.instance
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
                          color: Color(0xFF00F7FF),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'メッセージの読み込みに失敗しました',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'メッセージがありません',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isCurrentUser = data['senderId'] == currentUserId;
                  final timestamp = data['createdAt'] as Timestamp?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isCurrentUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isCurrentUser) ...[
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1A1B3F),
                              child: Text(
                                data['senderName']?[0] ?? '?',
                                style: const TextStyle(
                                  color: Color(0xFF00F7FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? const Color(0xFF00F7FF).withOpacity(0.1)
                                : const Color(0xFF1A1B3F).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00F7FF),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F7FF).withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  // child: Text(
                                  //   data['senderName'] ?? 'Unknown',
                                  //   style: const TextStyle(
                                  //     fontWeight: FontWeight.bold,
                                  //     fontSize: 12,
                                  //     color: Color(0xFF00F7FF),
                                  //   ),
                                  // ),
                                ),
                              Text(
                                data['message'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatTimestamp(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B3F),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F7FF).withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1221),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F7FF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F7FF).withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'メッセージを入力',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F7FF).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF00F7FF),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Color(0xFF00F7FF),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
