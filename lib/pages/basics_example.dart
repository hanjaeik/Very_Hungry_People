import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TableBasicsExample(),
    );
  }
}

class TableBasicsExample extends StatefulWidget {
  @override
  _TableBasicsExampleState createState() => _TableBasicsExampleState();
}

class _TableBasicsExampleState extends State<TableBasicsExample> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

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
          continue; // 형식이 올바르지 않으면 건너뜁니다.
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

      print('Loaded events: $events'); // 데이터를 콘솔에 출력하여 확인

      if (mounted) {
        setState(() {
          _events = events;
        });
      }
    } catch (error) {
      print('Error loading event data: $error');
    }
  }

  Future<void> _saveSelectedDay(DateTime selectedDay) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedDay', selectedDay.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('캘린더'),
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
              _saveSelectedDay(selectedDay);
              _loadEventsForMonth(focusedDay);

              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: AddPlanPage(
                      selectedDay: selectedDay,
                      events: _events,
                      reloadEventData: () => _loadEventsForMonth(selectedDay),
                      selectedTimeSlot: '',
                    ),
                  ),
                ),
              );
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
              if (events.isNotEmpty) {
                print('Events for $dateWithoutTime: ${events.map((e) => e.toString()).toList()}');
              } else {
                print('No events for $dateWithoutTime');
              }
              return events;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                DateTime dateWithoutTime = DateTime(day.year, day.month, day.day);
                if (events.isNotEmpty) {
                  print('Marker for $dateWithoutTime with events: ${events.map((e) => e.toString()).toList()}');
                  return _buildEventsMarker(events.length);
                } else {
                  print('No marker for $dateWithoutTime as there are no events');
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(int count) {
    return Positioned(
      bottom:-1,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}




class AddPlanPage extends StatefulWidget {
  final DateTime selectedDay;
  final Map<DateTime, List<dynamic>> events;
  final VoidCallback reloadEventData;
  final String selectedTimeSlot;


  const AddPlanPage({
    Key? key,
    required this.selectedDay,
    required this.events,
    required this.reloadEventData,
    required this.selectedTimeSlot,
  }) : super(key: key);

  @override
  _AddPlanPageState createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddPlanPage> {
  List<String> _selectedTimeSlots = [];
  bool _isAllSelected = false;

  @override
  void initState() {
    super.initState();
    _loadEventData(widget.selectedDay, widget.selectedTimeSlot);
  }

  void _clearSelectedTimeSlots() {
    setState(() {
      _selectedTimeSlots.clear();
      _isAllSelected = false;
    });
  }

  Future<void> _deleteSelectedTimeSlots() async {
    for (String timeSlot in _selectedTimeSlots) {
      await _deleteEventData(widget.selectedDay, timeSlot);
    }
    _clearSelectedTimeSlots();
    widget.reloadEventData();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedTimeSlots.clear();
      } else {
        _selectedTimeSlots = [
          '오전 01시', '오전 02시', '오전 03시', '오전 04시', '오전 05시', '오전 06시',
          '오전 07시', '오전 08시', '오전 09시', '오전 10시', '오전 11시', '오전 12시',
          '오후 01시', '오후 02시', '오후 03시', '오후 04시', '오후 05시', '오후 06시',
          '오후 07시', '오후 08시', '오후 09시', '오후 10시', '오후 11시', '오후 12시',
        ];
      }
      _isAllSelected = !_isAllSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedDay.month}월 ${widget.selectedDay.day}일'),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTimeSlotTile('오전 01시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 02시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 03시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 04시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 05시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 06시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 07시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 08시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 09시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 10시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 11시', widget.selectedDay, context),
            _buildTimeSlotTile('오전 12시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 01시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 02시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 03시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 04시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 05시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 06시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 07시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 08시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 09시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 10시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 11시', widget.selectedDay, context),
            _buildTimeSlotTile('오후 12시', widget.selectedDay, context),
          ],
        ),
      ),
      floatingActionButton: _selectedTimeSlots.isNotEmpty
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedTimeSlots.length != 24) // 총 24개 시간 슬롯
            Flexible(
              child: FloatingActionButton.extended(
                onPressed: _toggleSelectAll,
                label: Text(
                  _isAllSelected ? "선택 해제" : "전체 선택",
                  style: TextStyle(fontSize: 10), // 텍스트 크기 조정
                ),
                icon: Icon(
                  _isAllSelected ? Icons.deselect : Icons.select_all,
                  size: 20, // 아이콘 크기 조정
                ),
                extendedPadding: EdgeInsets.symmetric(horizontal: 16), // 패딩 조정
              ),
            ),
          SizedBox(width: 16),
          Flexible(
            child: FloatingActionButton.extended(
              onPressed: () {
                EventDialogHelper.showEventDialog(
                  context,
                  widget.selectedDay,
                  _selectedTimeSlots,
                  widget.reloadEventData,
                  _loadEventData,
                  _clearSelectedTimeSlots,
                );
              },
              label: Text(
                "일정추가",
                style: TextStyle(fontSize: 10), // 텍스트 크기 조정
              ),
              icon: Icon(
                Icons.add,
                size: 20, // 아이콘 크기 조정
              ),
              extendedPadding: EdgeInsets.symmetric(horizontal: 16), // 패딩 조정
            ),
          ),
          SizedBox(width: 16),
          Flexible(
            child: FloatingActionButton.extended(
              onPressed: _deleteSelectedTimeSlots,
              label: Text(
                "삭제",
                style: TextStyle(fontSize: 10), // 텍스트 크기 조정
              ),
              icon: Icon(
                Icons.delete,
                size: 20, // 아이콘 크기 조정
              ),
              extendedPadding: EdgeInsets.symmetric(horizontal: 16), // 패딩 조정
            ),
          ),
        ],
      )
          : null,
    );
  }

    Widget _buildTimeSlotTile(String timeSlot, DateTime selectedDay, BuildContext context) {
    return StreamBuilder<bool>(
      stream: EventService.checkEventExistence(selectedDay, timeSlot),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          bool hasEvent = snapshot.data ?? false;
          bool isSelected = _selectedTimeSlots.contains(timeSlot);

          return Column(
            children: [
              ListTile(
                title: Text(timeSlot),
                leading: isSelected ? Icon(Icons.check, color: Colors.red) : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTimeSlots.remove(timeSlot);
                    } else {
                      _selectedTimeSlots.add(timeSlot);
                    }
                    _isAllSelected = _selectedTimeSlots.length == 24; // 총 24개 시간 슬롯
                  });
                },
                trailing: GestureDetector(
                  onTap: () {
                    if (hasEvent) {
                      _PlanDialogHelper.showPlanDialog(
                        context,
                        selectedDay,
                        widget.events,
                        widget.reloadEventData,
                        timeSlot,
                        _loadEventData,
                        _deleteEventData,
                      );
                      _loadEventData(selectedDay, timeSlot);
                    }
                  },
                  child: hasEvent
                      ? Icon(Icons.article_outlined, size: 30, color: Colors.black)
                      : SizedBox.shrink(),
                ),
              ),
              Divider(),
            ],
          );
        }
      },
    );
  }

  Future<void> _deleteEventData(DateTime selectedDay, String timeSlot) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated.';
    }

    String user = currentUser.email ?? currentUser.uid ?? '';

    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
    String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";
    String timeSlotId = timeSlot.replaceAll('시', '시');

    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection('events')
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .collection('time')
        .doc(timeSlotId);

    try {
      await docRef.delete();
      print('Event data deleted successfully!');

      setState(() {
        widget.events[selectedDay]?.remove(timeSlot);
      });
      widget.reloadEventData();
    } catch (error) {
      print('Failed to delete event data: $error');
    }
  }

  Future<void> _loadEventData(DateTime selectedDay, String timeSlot) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated.';
    }

    String user = currentUser.email ?? currentUser.uid ?? '';

    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
    String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";
    String timeSlotId = timeSlot.replaceAll('시', '시');

    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection('events')
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .collection('time')
        .doc(timeSlotId);

    docRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        print("Event data loaded: ${docSnapshot.data()}");
        setState(() {
          if (!_selectedTimeSlots.contains(timeSlot)) {
            _selectedTimeSlots.add(timeSlot);
          }
          _isAllSelected = _selectedTimeSlots.length == 24; // 총 24개 시간 슬롯
        });
      } else {
        print("Event data not found for this time slot.");
      }
    }).catchError((error) {
      print('Error loading event data: $error');
    });
  }
}

class EventService {
  static Stream<bool> checkEventExistence(DateTime selectedDay, String timeSlot) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated.';
    }

    String user = currentUser.email ?? currentUser.uid ?? '';
    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
    String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user)
        .collection('events')
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .collection('time')
        .doc(timeSlot)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}

class EventDialogHelper {
  static TextEditingController _eventNameController = TextEditingController();

  static Future<void> showEventDialog(
      BuildContext context,
      DateTime selectedDay,
      List<String> selectedTimeSlots,
      VoidCallback reloadEventData,
      Function(DateTime, String) loadEventData,
      Function clearSelectedTimeSlots, // 타임슬롯 초기화 함수
      ) async {
    _eventNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('일정추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '일정을 추가해보세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    controller: _eventNameController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveMultipleEvents(
                      selectedDay,
                      _eventNameController.text,
                      selectedTimeSlots,
                      DateTime.now(),
                      DateTime.now().add(Duration(hours: 1)),
                      reloadEventData,
                    ).then((_) {
                      for (String timeSlot in selectedTimeSlots) {
                        loadEventData(selectedDay, timeSlot);
                      }
                      clearSelectedTimeSlots(); // 타임슬롯 초기화
                      Navigator.pop(context);
                    });
                  },
                  child: Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _saveMultipleEvents(
      DateTime selectedDay,
      String eventName,
      List<String> selectedTimeSlots,
      DateTime startTime,
      DateTime endTime,
      VoidCallback onComplete,
      ) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated.';
    }

    String user = currentUser.email ?? currentUser.uid ?? '';

    for (String timeSlot in selectedTimeSlots) {
      String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
      String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";
      String timeSlotId = timeSlot.replaceAll('시', '시');

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user)
          .collection('events')
          .doc(monthDocId)
          .collection('day')
          .doc(dayDocId)
          .collection('time')
          .doc(timeSlotId);

      try {
        await docRef.set({
          'eventName': eventName,
          'startTime': startTime,
          'endTime': endTime,
          'timeSlot': timeSlot,
        });

        // '추가됨' 문자열 필드 추가
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user)
            .collection('events')
            .doc(monthDocId)
            .collection('day')
            .doc(dayDocId)
            .set({
          '추가됨': '예',
        }, SetOptions(merge: true)); // 필드가 이미 있는 경우 기존 값과 병합

        print('Event data saved successfully for $timeSlot!');
      } catch (error) {
        print('Failed to save event data for $timeSlot: $error');
      }
    }

    onComplete();
  }
}

class _PlanDialogHelper {
  static TextEditingController _eventNameController = TextEditingController();

  static Future<void> showPlanDialog(
      BuildContext context,
      DateTime selectedDay,
      Map<DateTime, List<dynamic>> events,
      VoidCallback reloadEventData,
      String timeSlot,
      Function(DateTime, String) loadEventData,
      Function(DateTime, String) deleteEventData,
      ) async {
    _eventNameController.clear();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'User not authenticated.';
    }

    String userCollection = user.email ?? user.uid;

    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
    String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";
    String timeSlotId = timeSlot.replaceAll('시', '시');

    CollectionReference eventCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userCollection)
        .collection('events');

    DocumentReference docRef = eventCollection
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .collection('time')
        .doc(timeSlotId);

    docRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        var eventData = docSnapshot.data() as Map<String, dynamic>;
        _eventNameController.text = eventData['eventName'] ?? '';
      }

      showDialog(
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              _saveEventData(
                selectedDay,
                _eventNameController.text,
                DateTime.now(),
                DateTime.now().add(Duration(hours: 1)),
                timeSlot,
                reloadEventData,
              ).then((value) {
                reloadEventData();
              });
              return true;
            },
            child: AlertDialog(
              title: Text('일정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '내 일정',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    controller: _eventNameController,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    _saveEventData(
                      selectedDay,
                      _eventNameController.text,
                      DateTime.now(),
                      DateTime.now().add(Duration(hours: 1)),
                      timeSlot,
                      reloadEventData,
                    ).then((value) {
                      reloadEventData();
                      Navigator.pop(context);
                    });
                  },
                  child: Text('저장'),
                ),
                ElevatedButton(
                  onPressed: () {
                    reloadEventData();
                    deleteEventData(selectedDay, timeSlot);
                    Navigator.pop(context);
                  },
                  child: Text('삭제'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('닫기'),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

Future<void> _saveEventData(DateTime selectedDay, String eventName, DateTime startDateTime, DateTime endDateTime, String timeSlot, VoidCallback reloadEventData) async {
  try {
    if (eventName.isEmpty) {
      throw '이벤트 이름을 입력하세요.';
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'User not authenticated.';
    }

    String userCollection = user.email ?? user.uid;

    String monthDocId = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}";
    String dayDocId = "${selectedDay.day.toString().padLeft(2, '0')}일";
    String timeSlotId = timeSlot.replaceAll('시', '시');

    Map<String, dynamic> eventData = {
      'eventName': eventName,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
    };

    CollectionReference eventCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userCollection)
        .collection('events');

    // day 문서에 "추가됨" 필드 추가 또는 업데이트
    await eventCollection
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .set({
      'status': '추가됨',
    }, SetOptions(merge: true));

    // time 컬렉션에 이벤트 데이터 추가
    DocumentReference eventRef = eventCollection
        .doc(monthDocId)
        .collection('day')
        .doc(dayDocId)
        .collection('time')
        .doc(timeSlotId);

    await eventRef.set(eventData).then((_) {
      print('Event data saved successfully!');
      reloadEventData();
    });

  } catch (e) {
    print('Error saving event data: $e');
  }
}
