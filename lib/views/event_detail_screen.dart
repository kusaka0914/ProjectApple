import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import 'tabs/profile_tab.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isParticipating = false;
  bool _isVisible = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkParticipationStatus();
  }

  Future<void> _checkParticipationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isParticipating = widget.event.participantIds.contains(userId);
      _isVisible = widget.event.visibleParticipantIds.contains(userId);
      _isLoading = false;
    });
  }

  Future<void> _toggleParticipation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final eventRef =
          FirebaseFirestore.instance.collection('events').doc(widget.event.id);
      final isCurrentlyParticipating = widget.event.participantIds.contains(
        userId,
      );

      if (isCurrentlyParticipating) {
        await eventRef.update({
          'participantIds': FieldValue.arrayRemove([userId]),
          'visibleParticipantIds': FieldValue.arrayRemove([userId]),
          'participantsCount': FieldValue.increment(-1),
        });
      } else {
        await eventRef.update({
          'participantIds': FieldValue.arrayUnion([userId]),
          'visibleParticipantIds': _isVisible
              ? FieldValue.arrayUnion([userId])
              : FieldValue.arrayRemove([userId]),
          'participantsCount': FieldValue.increment(1),
        });
      }

      setState(() {
        _isParticipating = !isCurrentlyParticipating;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エラーが発生しました')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility() async {
    if (!_isParticipating) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final eventRef =
          FirebaseFirestore.instance.collection('events').doc(widget.event.id);
      await eventRef.update({
        'visibleParticipantIds': _isVisible
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });

      setState(() {
        _isVisible = !_isVisible;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('エラーが発生しました')));
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = widget.event.date.toDate();
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
        title: Text(
          widget.event.title,
          style: const TextStyle(
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B3F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.event.userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Color(0xFF1A1B3F),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xFF00F7FF),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '読み込み中...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                );
                              }
                              final userData = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              return Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF00F7FF),
                                        width: 1,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF1A1B3F),
                                      child: userData?['photoUrl'] != null
                                          ? ClipOval(
                                              child: Image.network(
                                                userData!['photoUrl'],
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
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
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    userData?['displayName'] ?? '不明なユーザー',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF00F7FF),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(eventDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF00F7FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF00F7FF),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.event.location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF00F7FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.event.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B3F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '参加予定者 (${widget.event.participantsCount}人)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildParticipantsList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _toggleParticipation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isParticipating
                              ? Colors.red.withOpacity(0.8)
                              : const Color(0xFF00F7FF),
                          foregroundColor:
                              _isParticipating ? Colors.white : Colors.black,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isParticipating ? '参加をキャンセル' : '参加する',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_isParticipating) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1B3F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F7FF),
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            '参加者として表示',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _isVisible,
                          onChanged: (value) => _toggleVisibility(),
                          activeColor: const Color(0xFF00F7FF),
                          inactiveThumbColor: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadParticipants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00F7FF),
            ),
          );
        }

        final participants = snapshot.data!;
        if (participants.isEmpty) {
          return const Text(
            '参加予定者はまだいません',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1221),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF1A1B3F),
                    child: participant['photoUrl'] != null
                        ? ClipOval(
                            child: Image.network(
                              participant['photoUrl'],
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
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
                ),
                title: Text(
                  participant['displayName'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileTab()),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadParticipants() async {
    final users = await Future.wait(
      widget.event.visibleParticipantIds.map(
        (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
      ),
    );

    return users.where((doc) => doc.exists).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'displayName': data['displayName'] ?? 'Unknown',
        'photoUrl': data['photoUrl'],
      };
    }).toList();
  }
}
