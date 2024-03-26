import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'LOGIN/login.dart';
import 'pages/basics_example.dart';
import 'pages/complex_example.dart';
import 'pages/events_example.dart';
import 'pages/multi_example.dart';
import 'pages/range_example.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스케줄 조율 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StartPage(),
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    TableBasicsExample(),
    TableRangeExample(),
    TableEventsExample(),
    TableMultiExample(),
    TableComplexExample(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스케줄 조율앱'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login'); // 로그인 페이지로 이동
            },
            child: Text('로그인 및 회원가입',
              style: TextStyle(color: Colors.black, fontSize: 16),),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('', style: TextStyle(color: Colors.white, fontSize: 24),),
              decoration: BoxDecoration(color: Colors.blue,),),
            ListTile(
              title: Text('캘린더'),
              onTap: () {
                _selectPage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('복잡한 캘린더'),
              onTap: () {
                _selectPage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('특정날자 선택'),
              onTap: () {
                _selectPage(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('다중선택'),
              onTap: () {
                _selectPage(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('범위선택'),
              onTap: () {
                _selectPage(4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

