import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import '/user_setting.dart';
import '/pages/schedule_page.dart';
import '/pages/chat_room.dart';

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

class FriendsMatchingPage extends StatefulWidget {
  @override
  _FriendsMatchingPageState createState() => _FriendsMatchingPageState();
}

class _FriendsMatchingPageState extends State<FriendsMatchingPage> {
  List<FriendUser> users = [];
  Set<String> friendsEmails = {};
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
          .where((user) => user.email != currentUserEmail && !friendsEmails.contains(user.email))
          .toList();
      isLoading = false;
    });
  }

  double calculateMatchScore(FriendUser user1, FriendUser user2) {
    double score = 0.0;
    if (user1.gender != user2.gender) score += 1.0; // 성별 다르면 가산점
    score += (10 - (user1.age - user2.age).abs()).toDouble(); // 나이 차이 적을수록 가산점
    return score;
  }

  void _showOptions(BuildContext context, String senderEmail, String senderName) {
    final userSettings = Provider.of<UserSettings>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.person),
              title: Text('$senderName님의 프로필 보기'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(email: senderEmail),
                  ),
                );
              },
            ),
            if (!userSettings.isPrivate)
              ListTile(
                leading: Icon(Icons.event),
                title: Text('$senderName님과 일정 비교하기'),
                onTap: () async {
                  Navigator.pop(context);
                  String? userEmail = await _findUserEmailByName(senderName);
                  if (userEmail != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SchedulePage(userEmail: userEmail, userName: senderName),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('사용자의 이메일을 찾을 수 없습니다.'),
                    ));
                  }
                },
              ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('$senderName님과 대화하기'),
              onTap: () {
                Navigator.pop(context);
                _createOrNavigateToChatRoom(senderEmail, senderName);
              },
            ),
            if (!friendsEmails.contains(senderEmail))
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('$senderName님에게 친구 요청 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  _showSendFriendRequestForm(context, senderEmail);
                },
              ),
          ],
        );
      },
    );
  }

  void _showSendFriendRequestForm(BuildContext context, String recipientEmail) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('친구 요청 보내기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('수신자: $recipientEmail'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _sendFriendRequest(recipientEmail);
                  Navigator.pop(context);
                },
                child: Text('요청 보내기'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendFriendRequest(String recipientEmail) async {
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      String senderEmail = user.email!;
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'senderEmail': senderEmail,
        'recipientEmail': recipientEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구 요청이 성공적으로 전송되었습니다.'),
      ));
    }
  }

  Future<String?> _findUserEmailByName(String userName) async {
    var result = await FirebaseFirestore.instance
        .collection('userpf')
        .where('name', isEqualTo: userName)
        .get();
    if (result.docs.isNotEmpty) {
      return result.docs.first.id;
    }
    return null;
  }

  Future<void> _createOrNavigateToChatRoom(String friendEmail, String friendName) async {
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String currentUserEmail = user.email!;
    String chatRoomId = _getChatRoomId(currentUserEmail, friendEmail);

    DocumentSnapshot chatRoomSnapshot = await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).get();

    if (!chatRoomSnapshot.exists) {
      await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).set({
        'members': [currentUserEmail, friendEmail],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(chatRoomTitle: '$friendName님과의 대화', chatRoomId: chatRoomId),
      ),
    );
  }

  String _getChatRoomId(String email1, String email2) {
    List<String> emails = [email1, email2];
    emails.sort();
    return emails.join('_');
  }

  // 이메일을 해시해서 색깔로 변환하는 함수
  Color _getColorFromEmail(String email) {
    final hash = email.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('친구 매칭'),
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
          : ListView.builder(
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
            onTap: () => _showOptions(context, user.email, user.name),
          );
        },
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final String email;

  UserProfilePage({required this.email});

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('userpf').doc(email).get();
    return snapshot.data() as Map<String, dynamic>?;
  }

  Color _getColorFromEmail(String email) {
    final hash = email.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 프로필'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.'));
          }

          final userInfo = snapshot.data!;
          return Transform.translate(
            offset: Offset(180, 150), // Adjust the offset values as needed
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _getColorFromEmail(email),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '이름: ${userInfo['name']}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '나이: ${userInfo['age']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '성별: ${userInfo['gender']}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
