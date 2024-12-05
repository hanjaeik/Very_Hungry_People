// group_schedule_selection.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'group_schedule.dart';
import 'schedule_page.dart';

class FriendUser {
  final String email;
  final String name;
  final int age;
  final String gender;
  final String image;
  final String phoneNumber;

  FriendUser({
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.phoneNumber,
  });

  factory FriendUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FriendUser(
      email: doc.id,
      name: data['name'] ?? '',
      age: int.parse(data['age']) ?? 0,
      gender: data['gender'] ?? '',
      image: data['image'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }
}

class GroupScheduleSelectionPage extends StatefulWidget {
  @override
  _GroupScheduleSelectionPageState createState() => _GroupScheduleSelectionPageState();
}

class _GroupScheduleSelectionPageState extends State<GroupScheduleSelectionPage> {
  List<FriendUser> users = [];
  Set<String> friendsEmails = {};
  Set<String> selectedEmails = {}; // 추가
  String currentUserEmail = 'current_user_email@example.com'; // 실제 사용자의 이메일로 설정
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsersAndFriends();
  }

  Future<void> fetchUsersAndFriends() async {
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email!;
    }

    // 친구 목록 가져오기
    var friendsSnapshot = await FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUserEmail)
        .collection('friends')
        .get();
    setState(() {
      friendsEmails = friendsSnapshot.docs.map((doc) => doc.id).toSet();
    });

    // 사용자 목록 가져오기
    var result = await FirebaseFirestore.instance.collection('userpf').get();
    setState(() {
      users = result.docs
          .map((doc) => FriendUser.fromFirestore(doc))
          .where((user) => user.email != currentUserEmail)
          .toList();
      isLoading = false;
    });
  }

  // 이메일을 해시해서 색깔로 변환하는 함수
  Color _getColorFromEmail(String email) {
    final hash = email.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }

  void _compareSchedules() {
    if (selectedEmails.length == 1) {
      String email = selectedEmails.first;
      FriendUser selectedUser = users.firstWhere((user) => user.email == email);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SchedulePage(userEmail: selectedUser.email, userName: selectedUser.name),
        ),
      );
    } else if (selectedEmails.length > 1) {
      List<FriendUser> selectedUsers = users.where((user) => selectedEmails.contains(user.email)).toList();
      List<String> userEmails = selectedUsers.map((user) => user.email).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupSchedule(userEmails: userEmails),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('그룹 일정 관리'),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('친구 찾는 중...'),
          ],
        ),
      )
          : users.isEmpty
          ? Center(child: Text('사용자를 찾을 수 없습니다.'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                FriendUser user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorFromEmail(user.email),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user.name),
                  subtitle: Text('나이: ${user.age}, 성별: ${user.gender}'),
                  trailing: Checkbox(
                    value: selectedEmails.contains(user.email),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedEmails.add(user.email);
                        } else {
                          selectedEmails.remove(user.email);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (selectedEmails.contains(user.email)) {
                        selectedEmails.remove(user.email);
                      } else {
                        selectedEmails.add(user.email);
                      }
                    });
                  },
                );
              },
            ),
          ),
          if (selectedEmails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _compareSchedules,
                child: Text('일정 비교하기'),
              ),
            ),
        ],
      ),
    );
  }
}
