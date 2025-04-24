import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FreeTimeEventDetailScreen extends StatelessWidget {
  final String eventId;

  const FreeTimeEventDetailScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  Future<void> _toggleParticipation(
    BuildContext context,
    Map<String, dynamic> eventData,
    List<dynamic> participants,
  ) async {
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
          .doc(eventId);

      if (isParticipating) {
        await eventRef.update({
          'participants': FieldValue.arrayRemove([user.uid]),
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('参加をキャンセルしました')),
        );
      } else {
        await eventRef.update({
          'participants': FieldValue.arrayUnion([user.uid]),
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('参加を申し込みました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF00F7FF).withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
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
              .doc(eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'エラーが発生しました: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F7FF)),
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
            final budget = eventData['budget'] as int?;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1B3F).withOpacity(0.8),
                        const Color(0xFF0B1221).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00F7FF).withOpacity(0.5),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventData['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F7FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F7FF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          eventData['type'] as String,
                          style: const TextStyle(
                            color: Color(0xFF00F7FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow(
                        context,
                        Icons.calendar_today,
                        DateFormat('yyyy/MM/dd HH:mm').format(date),
                      ),
                      if (eventData['location'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          context,
                          Icons.location_on,
                          eventData['location'] as String,
                        ),
                      ],
                      if (budget != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          context,
                          Icons.money,
                          '¥${NumberFormat('#,###').format(budget)}',
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context,
                        Icons.people,
                        '${participants.length}/${eventData['maxParticipants']}人',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1B3F).withOpacity(0.8),
                        const Color(0xFF0B1221).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00F7FF).withOpacity(0.5),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '参加者',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (participants.isEmpty)
                        const Text(
                          'まだ参加者はいません',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        )
                      else
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where(FieldPath.documentId,
                                  whereIn: participants)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF00F7FF)),
                                ),
                              );
                            }

                            return Column(
                              children: snapshot.data!.docs.map((doc) {
                                final userData =
                                    doc.data() as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF00F7FF)
                                                .withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF1A1B3F),
                                          child: userData['photoUrl'] != null
                                              ? ClipOval(
                                                  child: Image.network(
                                                    userData['photoUrl'],
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                      Icons.person,
                                                      size: 20,
                                                      color: Color(0xFF00F7FF),
                                                    ),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 20,
                                                  color: Color(0xFF00F7FF),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        userData['displayName'] ?? '不明なユーザー',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (user != null && eventData['createdBy'] != user.uid)
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isParticipating
                              ? Colors.red.withOpacity(0.8)
                              : const Color(0xFF00F7FF).withOpacity(0.8),
                          isParticipating
                              ? Colors.red.withOpacity(0.6)
                              : const Color(0xFF00F7FF).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isParticipating
                              ? Colors.red.withOpacity(0.3)
                              : const Color(0xFF00F7FF).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => _toggleParticipation(
                          context, eventData, participants),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isParticipating ? '参加をキャンセル' : '参加する',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
