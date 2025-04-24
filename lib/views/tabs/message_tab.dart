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
  final String openChatId = 'open_chat';

  @override
  void initState() {
    super.initState();
    _ensureOpenChatExists();
    _migrateExistingMessages();
  }

  Future<void> _ensureOpenChatExists() async {
    try {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error ensuring open chat exists: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _migrateExistingMessages() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final messages = await FirebaseFirestore.instance
          .collection('messages')
          .where('type', isNull: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'type': 'private'});
      }
      await batch.commit();
    } catch (e) {
      print('Error migrating messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(
        child: Text(
          'ログインが必要です',
          style: TextStyle(color: Colors.white),
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
            Icons.arrow_back_ios,
            color: Color(0xFF00F7FF),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'メッセージ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              )
            : ListView(
                children: [
                  // オープンチャット
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'オープンチャット',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00F7FF),
                            ),
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('messages')
                              .doc(openChatId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) {
                              return const SizedBox.shrink();
                            }

                            final lastMessageTime =
                                (data['lastMessageTime'] as Timestamp?)
                                    ?.toDate();
                            final lastMessage =
                                data['lastMessage'] as String? ?? '';
                            final participantsCount =
                                data['participantsCount'] as int? ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1B3F).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00F7FF),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F7FF)
                                        .withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00F7FF),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00F7FF)
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: Color(0xFF1A1B3F),
                                    child: Icon(
                                      Icons.groups,
                                      color: Color(0xFF00F7FF),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    const Text(
                                      'みんなのチャット',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00F7FF)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF00F7FF),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '$participantsCount人',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF00F7FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: lastMessage.isNotEmpty
                                    ? Text(
                                        lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      )
                                    : const Text(
                                        'メッセージはありません',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                trailing: lastMessageTime != null
                                    ? Text(
                                        _formatDateTime(lastMessageTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white38,
                                        ),
                                      )
                                    : null,
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
                            );
                          },
                        ),
                        if (!_isLoading && !_hasError)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'プライベートメッセージ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00F7FF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // プライベートメッセージ
                  StreamBuilder<List<Message>>(
                    stream: _getMessagesStream(currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Error in message stream: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'エラーが発生しました: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00F7FF),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 48,
                                color: Color(0xFF00F7FF),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'プライベートメッセージはまだありません',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'メッセージを送信して会話を始めましょう',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1B3F).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00F7FF),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00F7FF).withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: MessageListTile(message: message),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Stream<List<Message>> _getMessagesStream(String currentUserId) {
    print('Fetching messages for user: $currentUserId');
    return FirebaseFirestore.instance
        .collection('messages')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      print('Total documents in snapshot: ${snapshot.docs.length}');
      final messages = <Message>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Processing document ${doc.id}:');
        print('- type: ${data['type']}');
        print('- participants: ${data['participants']}');

        // オープンチャット以外かつ、自分が参加者に含まれているメッセージを取得
        if (data['type'] != 'open_chat') {
          final participants = List<String>.from(data['participants'] ?? []);
          if (participants.contains(currentUserId)) {
            try {
              final message = Message.fromFirestore(doc);
              messages.add(message);
              print('Added message ${doc.id} to list');
            } catch (e) {
              print('Error parsing message ${doc.id}: $e');
            }
          }
        }
      }

      print('Final message count: ${messages.length}');
      messages.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return messages;
    });
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isReceiver = message.receiverId == currentUserId;
    final displayName = isReceiver ? message.senderName : message.receiverName;
    final imageUrl =
        isReceiver ? message.senderImageUrl : message.receiverImageUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00F7FF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F7FF).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF1A1B3F),
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  color: Color(0xFF00F7FF),
                )
              : null,
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDateTime(message.lastMessageTime),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
          if (!message.isRead && message.receiverId == currentUserId)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00F7FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x8000F7FF),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
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
