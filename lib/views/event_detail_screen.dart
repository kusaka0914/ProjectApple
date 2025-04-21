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
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id);
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
          'visibleParticipantIds':
              _isVisible
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
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id);
      await eventRef.update({
        'visibleParticipantIds':
            _isVisible
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
      appBar: AppBar(
        title: Text(widget.event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.event.userId)
                              .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.person),
                              ),
                              SizedBox(width: 12),
                              Text('読み込み中...'),
                            ],
                          );
                        }
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child:
                                  userData?['photoUrl'] != null
                                      ? ClipOval(
                                        child: Image.network(
                                          userData!['photoUrl'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.person),
                                        ),
                                      )
                                      : const Icon(Icons.person),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              userData?['displayName'] ?? '不明なユーザー',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '日時: ${_formatDate(eventDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '場所: ${widget.event.location}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.event.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '参加予定者 (${widget.event.participantsCount}人)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildParticipantsList(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _toggleParticipation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isParticipating ? Colors.red : Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(_isParticipating ? '参加をキャンセル' : '参加する'),
                    ),
                    if (_isParticipating) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('参加者として表示'),
                        value: _isVisible,
                        onChanged: (value) => _toggleVisibility(),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildParticipantsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadParticipants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = snapshot.data!;
        if (participants.isEmpty) {
          return const Text('参加予定者はまだいません');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child:
                    participant['photoUrl'] != null
                        ? ClipOval(
                          child: Image.network(
                            participant['photoUrl'],
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.person),
                          ),
                        )
                        : const Icon(Icons.person),
              ),
              title: Text(participant['displayName'] ?? 'Unknown'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileTab()),
                );
              },
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
