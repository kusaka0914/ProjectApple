import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/free_time_event.dart';

class FreeTimeCalendar extends StatefulWidget {
  const FreeTimeCalendar({Key? key}) : super(key: key);

  @override
  _FreeTimeCalendarState createState() => _FreeTimeCalendarState();
}

class _FreeTimeCalendarState extends State<FreeTimeCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<FreeTimeEvent>> _events;
  late TextEditingController _searchController;
  late CalendarFormat _calendarFormat;
  late Stream<QuerySnapshot> _eventsStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = {};
    _searchController = TextEditingController();
    _calendarFormat = CalendarFormat.month;
    _eventsStream = FirebaseFirestore.instance
        .collection('free_time_events')
        .orderBy('date')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FreeTimeEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showEventsModal(selectedDay);
  }

  void _showCreateEventModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const CreateFreeTimeEventForm(),
      ),
    );
  }

  void _showEventsModal(DateTime day) {
    final events = _getEventsForDay(day);
    if (events.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              DateFormat('yyyy年MM月dd日').format(day),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description),
                      trailing: Text(
                          '${event.participants.length}/${event.maxParticipants}人'),
                      onTap: () => _showEventDetails(event),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(FreeTimeEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FreeTimeEventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // イベントデータの更新
          _events = {};
          for (var doc in snapshot.data!.docs) {
            final event = FreeTimeEvent.fromFirestore(doc);
            final eventDate = DateTime(
              event.date.toDate().year,
              event.date.toDate().month,
              event.date.toDate().day,
            );

            if (_events[eventDate] == null) {
              _events[eventDate] = [];
            }
            if (_searchQuery.isEmpty ||
                event.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                event.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) {
              _events[eventDate]!.add(event);
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
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
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'イベントを検索',
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
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
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
                child: TableCalendar<FreeTimeEvent>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2024, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
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
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
              const Divider(
                color: Color(0xFF00F7FF),
                thickness: 0.5,
                height: 32,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _events[_selectedDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final event = _events[_selectedDay]![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: InkWell(
                        onTap: () => _showEventDetails(event),
                        borderRadius: BorderRadius.circular(12),
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
                                DateFormat('yyyy年MM月dd日 HH:mm')
                                    .format(event.date.toDate()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF00F7FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '参加予定: ${event.participants.length}/${event.maxParticipants}人',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
