import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event.dart';
import '../event_detail_screen.dart';
import '../image_picker_screen.dart';

class EventTab extends StatefulWidget {
  const EventTab({super.key});

  @override
  State<EventTab> createState() => _EventTabState();
}

class _EventTabState extends State<EventTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    print('Loading events for month: ${_focusedDay.month}');
    final eventsSnapshot =
        await FirebaseFirestore.instance
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
    }

    setState(() {
      _events = newEvents;
    });
    print('Events loaded: $_events');
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 48),
          TableCalendar(
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
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerSize: 8,
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markerMargin: EdgeInsets.only(top: 8),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child:
                _selectedDay == null
                    ? const Center(child: Text('日付を選択してください'))
                    : _buildEventList(_getEventsForDay(_selectedDay!)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(child: Text('イベントはありません'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('参加予定: ${event.participantsCount}人'),
                if (event.visibleParticipantIds.isNotEmpty)
                  FutureBuilder<List<String>>(
                    future: _loadParticipantNames(event.visibleParticipantIds),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Text('参加者: ${snapshot.data!.join(", ")}');
                    },
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
            },
          ),
        );
      },
    );
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
