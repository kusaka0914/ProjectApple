import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../event_detail_screen.dart';
import '../image_picker_screen.dart';
import '../create_event_screen.dart';

class EventTab extends StatefulWidget {
  const EventTab({Key? key}) : super(key: key);

  @override
  _EventTabState createState() => _EventTabState();
}

class _EventTabState extends State<EventTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _matchedEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    print('Loading events for month: ${_focusedDay.month}');
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
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

    print('Found ${eventsSnapshot.docs.length} events');
    final newEvents = <DateTime, List<Event>>{};
    _matchedEventIds.clear();

    for (var doc in eventsSnapshot.docs) {
      final event = Event.fromFirestore(doc);
      print('Processing event: ${event.title} on ${event.date}');
      final eventDate = DateTime(
        event.date.toDate().year,
        event.date.toDate().month,
        event.date.toDate().day,
      );
      if (newEvents[eventDate] == null) {
        newEvents[eventDate] = [];
      }
      newEvents[eventDate]!.add(event);

      // 検索クエリに一致するかチェック
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (event.title.toLowerCase().contains(query)) {
          _matchedEventIds.add(doc.id);
        } else {
          // ユーザー名での検索
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(event.userId)
              .get();
          if (userData.exists) {
            final username = userData.get('username') as String? ?? '';
            if (username.toLowerCase().contains(query)) {
              _matchedEventIds.add(doc.id);
            }
          }
        }
      }
    }

    setState(() {
      _events = newEvents;
    });
    print('Events loaded: $_events');
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP');
    return formatter.format(date);
  }

  Future<void> _navigateToCreateEvent(File imageFile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          imageFile: imageFile,
          onEventCreated: () {
            // タブを切り替える（メッセージタブのインデックスを4と仮定）
            final tabController = DefaultTabController.of(context);
            if (tabController != null) {
              tabController.animateTo(4);
            }
          },
        ),
      ),
    );
  }

  // カレンダーのマーカービルダーを更新
  Widget? _buildMarker(List events, DateTime date) {
    if (events.isEmpty) return null;

    // 検索クエリがある場合、マッチしたイベントは赤色で表示
    final hasMatchedEvent =
        events.any((event) => _matchedEventIds.contains(event.id));
    final markerColor = hasMatchedEvent ? Colors.red : const Color(0xFF00F7FF);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(1),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: markerColor,
          boxShadow: [
            BoxShadow(
              color: markerColor,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        title: const Text(
          'イベント一覧',
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
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B1221),
                Color(0xFF1A1B3F),
                Color(0xFF0B1221),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B3F).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F7FF),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4000F7FF),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'イベントまたはユーザー名で検索',
                      hintStyle: TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF00F7FF)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _loadEvents();
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B3F).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF00F7FF),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4000F7FF),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration: BoxDecoration(
                      color: Color(0xFF00F7FF),
                      shape: BoxShape.circle,
                    ),
                    markerSize: 8,
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF00F7FF),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF1A1B3F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF00F7FF),
                        width: 1,
                      ),
                    ),
                    defaultTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.white70),
                    selectedTextStyle: TextStyle(color: Colors.black),
                    todayTextStyle: TextStyle(color: Color(0xFF00F7FF)),
                    outsideTextStyle: TextStyle(color: Colors.white38),
                    markersAlignment: Alignment.bottomCenter,
                    markerMargin: EdgeInsets.only(top: 8),
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
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      return _buildMarker(events, date);
                    },
                  ),
                ),
              ),
              const Divider(
                color: Color(0xFF00F7FF),
                thickness: 0.5,
                height: 32,
              ),
              _selectedDay == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: const Center(
                        child: Text(
                          '日付を選択してください',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children:
                          _buildEventListItems(_getEventsForDay(_selectedDay!)),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventListItems(List<Event> events) {
    final filteredEvents = _searchQuery.isEmpty
        ? events
        : events.where((event) => _matchedEventIds.contains(event.id)).toList();

    if (filteredEvents.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? '検索条件に一致するイベントが見つかりません'
                      : 'イベントはありません',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        )
      ];
    }

    return filteredEvents.map((event) {
      final eventDate = event.date.toDate();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B3F).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF00F7FF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4000F7FF),
              blurRadius: 10,
              spreadRadius: 1,
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
                        .doc(event.userId)
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
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
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
                      '参加予定: ${event.participantsCount}/${event.maxParticipants}人',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    if (event.visibleParticipantIds.isNotEmpty)
                      FutureBuilder<List<String>>(
                        future: _loadParticipantNames(
                          event.visibleParticipantIds,
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
    }).toList();
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
}
