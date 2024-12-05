import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/plan.dart';
import 'pages/multi_example.dart';
import 'pages/range_example.dart';
import 'pages/porfile.dart';
import 'pages/basics_example.dart';
import 'pages/friends_matching.dart';
import 'pages/Friends.dart';
import 'pages/talk.dart';
import '/login_page/login_page.dart';
import '/pages/events_example.dart';
import '/pages/Settings_Page.dart';
import '/pages/Group_page.dart'; // 추가

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _selectedIndex = 0;
  final String currentUserEmail = 'current_user_email@example.com';

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      EventSchedulerPage(),
      TableBasicsExample(),
      InfoForm(),
      UserInfoPage(),
      CommunityPage(),
      GoogleKeepClone(),
      FriendsMatchingPage(),
      FriendsPage(),
      ChatListPage(),
      GroupScheduleSelectionPage(), // 추가
    ];
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage(onTap: () {})),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스케줄 조율앱'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // 톱니바퀴 아이콘
            onPressed: _openSettings, // 버튼 클릭 시 환경설정 페이지로 이동
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                '',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            ListTile(
              title: Text('일정 구분'),
              onTap: () {
                _selectPage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('캘린더'),
              onTap: () {
                _selectPage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('프로필 입력'),
              onTap: () {
                _selectPage(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('프로필'),
              onTap: () {
                _selectPage(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('소모임 커뮤니티'),
              onTap: () {
                _selectPage(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('공유 메모장'),
              onTap: () {
                _selectPage(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('친구 매칭'),
              onTap: () {
                _selectPage(6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('친구 관리'),
              onTap: () {
                _selectPage(7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('채팅'),
              onTap: () {
                _selectPage(8);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('그룹 일정 관리'), // 추가
              onTap: () {
                _selectPage(9); // 추가
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
