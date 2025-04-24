import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'free_time_event_detail_screen.dart';
import 'create_free_time_event_form.dart';

class FreeTimeEventListScreen extends StatefulWidget {
  const FreeTimeEventListScreen({Key? key}) : super(key: key);

  @override
  State<FreeTimeEventListScreen> createState() =>
      _FreeTimeEventListScreenState();
}

class _FreeTimeEventListScreenState extends State<FreeTimeEventListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _matchedEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('free_time_events')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(_focusedDay.year, _focusedDay.month, 1),
          ),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(
            DateTime(_focusedDay.year, _focusedDay.month + 1, 1),
          ),
        )
        .get();

    if (!mounted) return;

    final newEvents = <DateTime, List<Map<String, dynamic>>>{};
    _matchedEventIds.clear();

    for (var doc in eventsSnapshot.docs) {
      final event = doc.data();
      event['id'] = doc.id;
      final eventDate = (event['date'] as Timestamp).toDate();
      final dateKey = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
      );

      if (newEvents[dateKey] == null) {
        newEvents[dateKey] = [];
      }
      newEvents[dateKey]!.add(event);

      // 検索クエリに一致するイベントをチェック
      if (_searchQuery.isNotEmpty) {
        if ((event['title'] as String)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())) {
          _matchedEventIds.add(doc.id);
          continue;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(event['createdBy'] as String)
            .get();

        if (!mounted) return;

        final userData = userDoc.data();
        final userName = userData?['displayName'] ?? '';

        if (userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          _matchedEventIds.add(doc.id);
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _events = newEvents;
    });
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _matchedEventIds.clear();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (query == _searchQuery) {
        _loadEvents();
      }
    });
  }

  bool _hasMatchedEventForDay(DateTime day) {
    final events = _getEventsForDay(day);
    return events.any((event) => _matchedEventIds.contains(event['id']));
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP');
    return formatter.format(date);
  }

  Future<List<String>> _loadParticipantNames(List<String> userIds) async {
    final users = await Future.wait(
      userIds.map(
        (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
      ),
    );
    return users
        .where((doc) => doc.exists)
        .map(
          (doc) =>
              (doc.data() as Map<String, dynamic>)['displayName'] as String? ??
              'Unknown',
        )
        .toList();
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventDate = (event['date'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(event['createdBy'] as String)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF1A1B3F),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF00F7FF),
                        ),
                      );
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
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
                            radius: 16,
                            backgroundColor: const Color(0xFF1A1B3F),
                            child: userData?['photoUrl'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      userData!['photoUrl'],
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                        const SizedBox(width: 8),
                        Text(
                          userData?['displayName'] ?? '不明なユーザー',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FreeTimeEventDetailScreen(
                    eventId: event['id'] as String,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(eventDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00F7FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '参加予定: ${(event['participants'] as List).length}/${event['maxParticipants']}人',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  if (event['participants'] != null)
                    FutureBuilder<List<String>>(
                      future: _loadParticipantNames(
                        List<String>.from(event['participants'] as List),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '参加者: ${snapshot.data!.join(", ")}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventListSliver(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'イベントはありません',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final filteredEvents = _searchQuery.isEmpty
        ? events
        : events
            .where((event) => _matchedEventIds.contains(event['id']))
            .toList();

    if (filteredEvents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            '「$_searchQuery」に一致するイベントはありません',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildEventCard(filteredEvents[index]),
        childCount: filteredEvents.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1221),
            Color(0xFF1A1B3F),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            '今ひまカレンダー',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00F7FF),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F7FF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF00F7FF),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1A1B3F),
                            Color(0xFF0B1221),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const CreateFreeTimeEventForm(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'イベントまたはユーザー名で検索',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF00F7FF)),
                        filled: true,
                        fillColor: const Color(0xFF1A1B3F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF00F7FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF00F7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF00F7FF), width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1B3F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00F7FF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F7FF).withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadEvents();
                      },
                      eventLoader: _getEventsForDay,
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          final hasMatchedEvent = _hasMatchedEventForDay(date);

                          return Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(1),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    hasMatchedEvent && _searchQuery.isNotEmpty
                                        ? Colors.red
                                        : const Color(0xFF00F7FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasMatchedEvent &&
                                            _searchQuery.isNotEmpty
                                        ? Colors.red.withOpacity(0.5)
                                        : const Color(0xFF00F7FF),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        markersMaxCount: 1,
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFF00F7FF),
                          shape: BoxShape.circle,
                        ),
                        markerSize: 8,
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF00F7FF),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF1A1B3F),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00F7FF),
                            width: 1,
                          ),
                        ),
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle:
                            const TextStyle(color: Colors.white70),
                        selectedTextStyle: const TextStyle(color: Colors.black),
                        todayTextStyle:
                            const TextStyle(color: Color(0xFF00F7FF)),
                        outsideTextStyle:
                            const TextStyle(color: Colors.white38),
                        markersAlignment: Alignment.bottomCenter,
                        markerMargin: const EdgeInsets.only(top: 8),
                      ),
                      headerStyle: const HeaderStyle(
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                        formatButtonVisible: false,
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Color(0xFF00F7FF),
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Color(0xFF00F7FF),
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white70),
                        weekendStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const Divider(
                    color: Color(0xFF00F7FF),
                    thickness: 0.5,
                    height: 32,
                  ),
                ],
              ),
            ),
            _selectedDay == null
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        '日付を選択してください',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : _buildEventListSliver(_getEventsForDay(_selectedDay!)),
          ],
        ),
      ),
    );
  }
}
