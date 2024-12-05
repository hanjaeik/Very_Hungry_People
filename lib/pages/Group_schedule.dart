import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';

class GroupSchedule extends StatefulWidget {
  final List<String> userEmails;

  GroupSchedule({required this.userEmails});

  @override
  _GroupScheduleState createState() => _GroupScheduleState();
}

class _GroupScheduleState extends State<GroupSchedule> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  Map<DateTime, List<dynamic>> _myEvents = {};
  Map<String, String> userNames = {};
  Map<String, Color> userColors = {}; // 사용자별 색상

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _generateUserColors();
    _fetchUserNames().then((_) {
      _loadEventsForMonth(_focusedDay);
    });
  }

  // 사용자별 색상 생성
  void _generateUserColors() {
    final random = Random();
    for (String email in widget.userEmails) {
      userColors[email] = Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
  }

  Future<void> _fetchUserNames() async {
    for (String email in widget.userEmails) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('userpf').doc(email).get();
      if (userDoc.exists) {
        userNames[email] = userDoc['name'];
      }
    }
  }

  Future<void> _loadEventsForMonth(DateTime selectedDay) async {
    if (!mounted) return;

    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";

    // 다른 사용자들의 일정 불러오기
    for (String userEmail in widget.userEmails) {
      await _loadUserEvents(userEmail, monthDocId, selectedDay);
    }

    // 현재 사용자 일정 불러오기
    await _loadMyEvents(selectedDay.year, selectedDay.month);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserEvents(String userEmail, String monthDocId, DateTime selectedDay) async {
    CollectionReference dayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
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
          continue; // 형식이 올바르지 않으면 건너뜁니다.
        }
        DateTime day = DateTime(selectedDay.year, selectedDay.month, dayInt);

        CollectionReference timeRef = dayRef.doc(dayDocId).collection('time');
        QuerySnapshot timeSnapshot = await timeRef.get();
        List<dynamic> dayEvents = [];

        for (var timeDoc in timeSnapshot.docs) {
          Map<String, dynamic> timeData = timeDoc.data() as Map<String, dynamic>;
          timeData['email'] = userEmail; // 이벤트에 이메일 추가
          dayEvents.add(timeData);
        }

        if (dayEvents.isNotEmpty) {
          if (_events[day] == null) {
            _events[day] = [];
          }
          _events[day]!.addAll(dayEvents);
        }
      }

      print('Loaded events for $userEmail: $events'); // 데이터를 콘솔에 출력하여 확인
    } catch (error) {
      print('Error loading event data for $userEmail: $error');
    }
  }

  Future<void> _loadMyEvents(int year, int month) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String myEmail = user.email!;
    String monthDocId = "$year-${month.toString().padLeft(2, '0')}";

    CollectionReference dayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(myEmail)
        .collection('events')
        .doc(monthDocId)
        .collection('day');

    try {
      QuerySnapshot daySnapshot = await dayRef.get();
      Map<DateTime, List<dynamic>> myEvents = {};

      for (var dayDoc in daySnapshot.docs) {
        String dayDocId = dayDoc.id;
        int dayInt = int.tryParse(dayDocId.replaceAll('일', '')) ?? -1;
        if (dayInt == -1) {
          print('Invalid dayDocId format: $dayDocId');
          continue; // 형식이 올바르지 않으면 건너뜁니다.
        }
        DateTime day = DateTime(year, month, dayInt);

        CollectionReference timeRef = dayRef.doc(dayDocId).collection('time');
        QuerySnapshot timeSnapshot = await timeRef.get();
        List<dynamic> dayEvents = [];

        for (var timeDoc in timeSnapshot.docs) {
          dayEvents.add(timeDoc.data());
        }

        if (dayEvents.isNotEmpty) {
          myEvents[day] = dayEvents;
        }
      }

      print('Loaded my events: $myEvents'); // 데이터를 콘솔에 출력하여 확인

      if (mounted) {
        setState(() {
          _myEvents = myEvents;
        });
      }
    } catch (error) {
      print('Error loading my event data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('그룹 일정 비교 (${userNames.values.join(', ')})'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadEventsForMonth(focusedDay);
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
              final myEvents = _myEvents[dateWithoutTime] ?? [];
              final overlappingEvents = events.isNotEmpty && myEvents.isNotEmpty;
              return [...events, ...myEvents, if (overlappingEvents) '겹침'];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                DateTime dateWithoutTime = DateTime(day.year, day.month, day.day);
                bool hasMyEvents = _myEvents.containsKey(dateWithoutTime);
                bool hasOtherEvents = _events.containsKey(dateWithoutTime);
                bool isOverlapping = hasMyEvents && hasOtherEvents;

                if (isOverlapping) {
                  return Transform.translate(
                    offset: Offset(0, 1),
                    child: _buildEventsMarker(0, Colors.green),
                  );
                } else if (hasMyEvents) {
                  return Transform.translate(
                    offset: Offset(0, 1),
                    child: _buildEventsMarker(_myEvents[dateWithoutTime]?.length ?? 0, Colors.blue),
                  );
                } else if (hasOtherEvents) {
                  return Transform.translate(
                    offset: Offset(0, 1),
                    child: _buildEventsMarker(
                        _events[dateWithoutTime]?.length ?? 0,
                        userColors[_events[dateWithoutTime]!.first['email']]!),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          Wrap(
            spacing: 16.0,
            children: _buildLegendItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(int count, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: count > 0 && color != Colors.green
          ? Center(
        child: Text(
          '$count',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      )
          : null,
    );
  }

  List<Widget> _buildLegendItems() {
    List<Widget> legendItems = [];

    legendItems.add(_buildLegendItem(Colors.blue, '나의 일정'));
    for (String email in widget.userEmails) {
      legendItems.add(_buildLegendItem(userColors[email]!, '${userNames[email] ?? email}의 일정'));
    }
    legendItems.add(_buildLegendItem(Colors.green, '겹치는 일정'));

    return legendItems;
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
