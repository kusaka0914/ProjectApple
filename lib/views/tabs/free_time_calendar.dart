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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'イベントを検索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              TableCalendar<FreeTimeEvent>(
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
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _events[_selectedDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final event = _events[_selectedDay]![index];
                    return Card(
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
