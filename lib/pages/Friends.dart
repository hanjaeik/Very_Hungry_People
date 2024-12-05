import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Provider 패키지 가져오기
import '/user_setting.dart';
import 'settings_page.dart'; // 올바른 경로로 변경 필요
import '/pages/chat_room.dart';
import '/pages/schedule_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserSettings(), // UserSettings 제공
      child: MaterialApp(
        title: '스케줄 조율앱',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: FriendsPage(),
      ),
    );
  }
}

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> friends = [];
  List<String> friendRequests = [];
  String currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email!;
      await _loadFriends();
      await _loadFriendRequests();
    }
  }

  Future<void> _loadFriends() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUserEmail)
        .collection('friends')
        .get();

    List<Map<String, dynamic>> loadedFriends = [];

    for (var doc in snapshot.docs) {
      String friendEmail = doc.id;
      var friendSnapshot = await FirebaseFirestore.instance.collection('userpf').doc(friendEmail).get();
      if (friendSnapshot.exists) {
        Map<String, dynamic> friendData = friendSnapshot.data() as Map<String, dynamic>;
        loadedFriends.add({
          'email': friendEmail,
          'name': friendData['name'],
          'age': friendData['age'],
          'gender': friendData['gender'],
        });
      }
    }

    setState(() {
      friends = loadedFriends;
    });
  }

  Future<void> _loadFriendRequests() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('recipientEmail', isEqualTo: currentUserEmail)
        .get();

    setState(() {
      friendRequests = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['senderEmail'] as String)
          .toList();
    });
  }

  void _showFriendRequestForm(BuildContext context) {
    final TextEditingController _friendRequestController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('친구 요청 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              friendRequests.isEmpty
                  ? Text('친구 요청이 없습니다.')
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: friendRequests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(friendRequests[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        _acceptFriendRequest(friendRequests[index]);
                      },
                    ),
                  );
                },
              ),
              Divider(),
              Text('친구 요청 보내기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _friendRequestController,
                decoration: InputDecoration(
                  labelText: '이메일 입력',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _sendFriendRequest(_friendRequestController.text);
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
    User? user = FirebaseAuth.instance.currentUser;
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

  Future<void> _acceptFriendRequest(String senderEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String recipientEmail = user.email!;

      // 친구 관계를 저장
      await FirebaseFirestore.instance.collection('friends').doc(recipientEmail).collection('friends').doc(senderEmail).set({});
      await FirebaseFirestore.instance.collection('friends').doc(senderEmail).collection('friends').doc(recipientEmail).set({});

      // 친구 요청을 삭제
      var snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderEmail', isEqualTo: senderEmail)
          .where('recipientEmail', isEqualTo: recipientEmail)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // 친구 목록과 친구 요청 목록을 다시 불러옴
      await _loadFriends();
      await _loadFriendRequests();

      // 친구 요청 수락 알림
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구 요청을 수락했습니다.'),
      ));
    }
  }

  Future<void> _deleteFriend(String friendEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;

      // 친구 관계를 삭제
      await FirebaseFirestore.instance.collection('friends').doc(userEmail).collection('friends').doc(friendEmail).delete();
      await FirebaseFirestore.instance.collection('friends').doc(friendEmail).collection('friends').doc(userEmail).delete();

      // 친구 목록 다시 불러오기
      await _loadFriends();

      // 친구 삭제 알림
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구가 삭제되었습니다.'),
      ));
    }
  }

  // 사용자의 이름을 클릭했을 때 옵션을 표시하는 메서드
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
              title: Text('$senderName 님과 대화하기'),
              onTap: () async {
                Navigator.pop(context);
                String chatRoomId = _getChatRoomId(currentUserEmail, senderEmail);
                bool chatRoomExists = await _chatRoomExists(chatRoomId);
                if (chatRoomExists) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        chatRoomTitle: '$senderName님과의 대화',
                        chatRoomId: chatRoomId,
                      ),
                    ),
                  );
                } else {
                  await _createOrNavigateToChatRoom(senderEmail, senderName);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.person_remove),
              title: Text('$senderName 님 친구 삭제'),
              onTap: () {
                Navigator.pop(context);
                _deleteFriend(senderEmail);
              },
            ),
          ],
        );
      },
    );
  }

  // 사용자 이름을 이용해 이메일을 찾는 메서드
  Future<String?> _findUserEmailByName(String userName) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('userpf')
        .where('name', isEqualTo: userName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // 첫 번째 문서의 ID (이메일) 반환
    }
    return null;
  }

  Future<void> _createOrNavigateToChatRoom(String friendEmail, String friendName) async {
    User? user = FirebaseAuth.instance.currentUser;
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

  Future<bool> _chatRoomExists(String chatRoomId) async {
    DocumentSnapshot chatRoomSnapshot = await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).get();
    return chatRoomSnapshot.exists;
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
        title: Text('친구 관리'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: friends.isEmpty
                ? Center(child: Text('아직은 친구가 없네요!'))
                : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorFromEmail(friends[index]['email']),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text('${friends[index]['name']}'),
                  subtitle: Text('나이: ${friends[index]['age']}, 성별: ${friends[index]['gender']}'),
                  onTap: () {
                    _showOptions(context, friends[index]['email'], friends[index]['name']);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  _showFriendRequestForm(context);
                },
                child: Text('친구요청'),
              ),
            ),
          ),
        ],
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
