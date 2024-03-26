// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../utils.dart';

class TableBasicsExample extends StatefulWidget {
  @override
  _TableBasicsExampleState createState() => _TableBasicsExampleState();
}

class _TableBasicsExampleState extends State<TableBasicsExample> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // 달력 형식을 나타내는 변수
  DateTime _focusedDay = DateTime.now(); // 포커스된 날짜
  DateTime? _selectedDay; // 선택된 날짜

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: TableCalendar(
        firstDay: kFirstDay, // 달력의 첫 날짜
        lastDay: kLastDay, // 달력의 마지막 날짜
        focusedDay: _focusedDay, // 포커스된 날짜 설정
        calendarFormat: _calendarFormat, // 달력의 형식 설정
        selectedDayPredicate: (day) {
          // 선택된 날짜를 결정하기 위한 조건 함수
          // 이 함수가 true를 반환하면 `day`는 선택된 것으로 표시됩니다.

          // `isSameDay`를 사용하여 비교되는 DateTime 객체의 시간 부분을 무시하는 것이 권장됩니다.
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            // 선택된 날짜를 업데이트할 때 `setState()`를 호출합니다.
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            // 달력 형식을 업데이트할 때 `setState()`를 호출합니다.
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          // 여기서 `setState()`를 호출할 필요가 없습니다.
          _focusedDay = focusedDay;
        },
      ),
    );
  }
}
