import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../tabs/profile_tab.dart';

class FreeTimeEventDetailScreen extends StatefulWidget {
  final String eventId;

  const FreeTimeEventDetailScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  State<FreeTimeEventDetailScreen> createState() =>
      _FreeTimeEventDetailScreenState();
}

class _FreeTimeEventDetailScreenState extends State<FreeTimeEventDetailScreen> {
  bool _isLoading = false;

  Future<void> _toggleParticipation(
    Map<String, dynamic> eventData,
    List<dynamic> participants,
  ) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
        return;
      }

      final isParticipating = participants.contains(user.uid);
      final maxParticipants = eventData['maxParticipants'] as int;

      if (!isParticipating && participants.length >= maxParticipants) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('募集人数が上限に達しています')),
        );
        return;
      }

      final eventRef = FirebaseFirestore.instance
          .collection('free_time_events')
          .doc(widget.eventId);

      if (isParticipating) {
        await eventRef.update({
          'participants': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await eventRef.update({
          'participants': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラーが発生しました')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF00F7FF),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList(List<dynamic> participants) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait(
        participants.map(
          (id) => FirebaseFirestore.instance
              .collection('users')
              .doc(id.toString())
              .get()
              .then((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return {
              'id': doc.id,
              'displayName': data?['displayName'] ?? '不明なユーザー',
              'photoUrl': data?['photoUrl'],
            };
          }),
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00F7FF),
            ),
          );
        }

        final participantsList = snapshot.data!;
        if (participantsList.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Color(0xFF00F7FF),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '参加予定者はまだいません',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participantsList.length,
          separatorBuilder: (context, index) => const Divider(
            color: Colors.white12,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final participant = participantsList[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A1B3F),
                child: participant['photoUrl'] != null
                    ? ClipOval(
                        child: Image.network(
                          participant['photoUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            color: Color(0xFF00F7FF),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF00F7FF),
                      ),
              ),
              title: Text(
                participant['displayName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF00F7FF),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileTab(
                      key: ValueKey(participant['id']),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'イベント詳細',
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('free_time_events')
              .doc(widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              );
            }

            final eventData = snapshot.data!.data() as Map<String, dynamic>?;
            if (eventData == null) {
              return const Center(
                child: Text(
                  'イベントが見つかりません',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final participants = eventData['participants'] as List<dynamic>;
            final user = FirebaseAuth.instance.currentUser;
            final isParticipating =
                user != null && participants.contains(user.uid);
            final date = (eventData['date'] as Timestamp).toDate();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主催者情報
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(eventData['createdBy'])
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileTab(
                                key: ValueKey(eventData['createdBy']),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1A1B3F),
                              child: userData?['photoUrl'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        userData!['photoUrl'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.person,
                                          color: Color(0xFF00F7FF),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Color(0xFF00F7FF),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              userData?['displayName'] ?? '不明なユーザー',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF00F7FF),
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // イベントタイトル
                  Text(
                    eventData['title'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // イベント写真
                  if (eventData['imageUrl'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        eventData['imageUrl'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // イベント概要
                  Text(
                    eventData['description'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // イベント基本情報
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        DateFormat('yyyy年MM月dd日 HH:mm').format(date),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_on,
                        eventData['location'] as String,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.group,
                        '${participants.length}/${eventData['maxParticipants']}人',
                      ),
                      if (eventData['budget'] != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.money,
                          '¥${NumberFormat('#,###').format(eventData['budget'])}',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 参加者リスト
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '参加予定者 (${participants.length}人)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00F7FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildParticipantsList(participants),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 参加ボタン
                  if (user != null && eventData['createdBy'] != user.uid)
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _toggleParticipation(eventData, participants),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isParticipating
                            ? Colors.red.withOpacity(0.9)
                            : const Color(0xFF00F7FF),
                        foregroundColor:
                            isParticipating ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isParticipating ? '参加をキャンセル' : '参加する',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
