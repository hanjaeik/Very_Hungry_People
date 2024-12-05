import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/pages/basics_example.dart'; // 경로는 필요에 따라 수정하세요

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EventSchedulerPage(),
    );
  }
}

class EventSchedulerPage extends StatefulWidget {
  @override
  EventSchedulerPageState createState() => EventSchedulerPageState();
}

class EventSchedulerPageState extends State<EventSchedulerPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  List<Event> _recommendedEvents = [];
  Set<DateTime> _emptyDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEventsForMonth(_focusedDay);
  }

  Future<void> _loadEventsForMonth(DateTime selectedDay) async {
    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated.';
    }

    String user = currentUser.email ?? currentUser.uid ?? '';
    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";

    CollectionReference dayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection('events')
        .doc(monthDocId)
        .collection('day');

    try {
      QuerySnapshot daySnapshot = await dayRef.get();
      Map<DateTime, List<dynamic>> events = {};

      for (var dayDoc in daySnapshot.docs) {
        String dayDocId = dayDoc.id;
        int dayInt = int.tryParse(dayDocId.replaceAll('일', '')) ?? -1;
        if (dayInt == -1) {
          print('Invalid dayDocId format: $dayDocId');
          continue;
        }
        DateTime day = DateTime(selectedDay.year, selectedDay.month, dayInt);

        CollectionReference timeRef = dayRef.doc(dayDocId).collection('time');
        QuerySnapshot timeSnapshot = await timeRef.get();
        List<dynamic> dayEvents = [];

        for (var timeDoc in timeSnapshot.docs) {
          dayEvents.add(timeDoc.data());
        }

        if (dayEvents.isNotEmpty) {
          events[day] = dayEvents;
        }
      }

      print('Loaded events: $events');

      if (mounted) {
        setState(() {
          _events = events;
          _emptyDays = _calculateEmptyDays(selectedDay, events);
        });
      }
    } catch (error) {
      print('Error loading event data: $error');
    }
  }

  Set<DateTime> _calculateEmptyDays(DateTime selectedDay, Map<DateTime, List<dynamic>> events) {
    Set<DateTime> emptyDays = {};
    DateTime firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
    DateTime lastDayOfMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0);

    for (int i = 0; i <= lastDayOfMonth.day; i++) {
      DateTime day = firstDayOfMonth.add(Duration(days: i));
      if (events[day] == null || events[day]!.isEmpty) {
        emptyDays.add(day);
      }
    }
    return emptyDays;
  }

  Future<void> _saveSelectedDay(DateTime selectedDay) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedDay', selectedDay.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 구분'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _saveSelectedDay(selectedDay);
              await _loadEventsForMonth(focusedDay);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEventsForMonth(focusedDay);
            },
            eventLoader: (day) {
              DateTime dateWithoutTime = DateTime(day.year, day.month, day.day);
              final events = _events[dateWithoutTime] ?? [];
              return events;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                DateTime dateWithoutTime = DateTime(day.year, day.month, day.day);
                bool hasEvents = _events[dateWithoutTime] != null && _events[dateWithoutTime]!.isNotEmpty;
                bool isEmptyDay = _emptyDays.contains(dateWithoutTime);

                if (hasEvents) {
                  return Positioned(
                    bottom: -1,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_events[dateWithoutTime]!.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (isEmptyDay) {
                  return Positioned(
                    bottom: -1,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                } else {
                  return null;
                }
              },
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[200],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendItem(color: Colors.blue, text: '일정 존재'),
                SizedBox(width: 16),
                LegendItem(color: Colors.yellow, text: '일정 없음'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '비어있는 일정을 통해 친구와 일정을 맞춰 보아요!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TableBasicsExample()),
                );
              },
              child: Text('일정 추가하러 가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final DateTime startTime;
  final DateTime endTime;
  final String title;

  Event({required this.startTime, required this.endTime, required this.title});

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      title: data['title'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'title': title,
    };
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
