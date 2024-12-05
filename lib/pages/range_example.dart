import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/schedule_page.dart';
import '/pages/chat_room.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여행 소모임',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CommunityPage(),
    );
  }
}

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _controller = TextEditingController();
  String selectedRegion = '서울'; // 기본적으로 서울이 선택되어 있음
  String? currentUserId; // 현재 사용자의 UID
  String senderName = ''; // 사용자 이름
  List<String> friendRequests = [];
  List<String> currentFriends = []; // 현재 친구 목록

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // 사용자 정보 불러오기
    _loadFriendRequests(); // 친구 요청 불러오기
    _loadFriends(); // 현재 친구 목록 불러오기
  }

  // 현재 사용자 정보를 불러와서 사용자 이름 설정
  void _loadCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid; // 현재 사용자의 UID 설정

      // Firebase Authentication에서 사용자 이메일 가져오기
      String? userEmail = user.email;
      if (userEmail != null) {
        // Firestore에서 사용자의 이름 가져오기
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('userpf').doc(userEmail).get();
        if (snapshot.exists) {
          Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
          if (userData != null) {
            setState(() {
              senderName = userData['name'] ?? 'Unknown'; // 이름 설정
            });
          }
        }
      }
    }
  }

  // 친구 요청 목록 불러오기
  Future<void> _loadFriendRequests() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('recipientEmail', isEqualTo: userEmail)
          .get();
      setState(() {
        friendRequests = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['senderEmail'] as String).toList();
      });
    }
  }

  // 현재 친구 목록 불러오기
  Future<void> _loadFriends() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('friends')
          .doc(userEmail)
          .collection('friends')
          .get();
      setState(() {
        currentFriends = snapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  // 친구 요청 보내기 폼을 표시하는 메서드
  void _showSendFriendRequestForm(BuildContext context, String recipientEmail) {
    if (currentFriends.contains(recipientEmail)) {
      // 이미 친구인 경우 친구 요청 폼을 표시하지 않음
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('이미 친구입니다.'),
      ));
      return;
    }

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
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String senderEmail = user.email!;
      await FirebaseFirestore.instance.collection('friend_requests').add({
          'senderEmail': senderEmail,
          'recipientEmail': recipientEmail,
      'timestamp': FieldValue.serverTimestamp(),
      });
      // 친구 요청이 성공적으로 전송되었음을 사용자에게 알림
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

      // 친구 요청 목록을 다시 불러옴
      await _loadFriendRequests();

      // 친구 요청 수락 알림
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구 요청을 수락했습니다.'),
      ));

      // 친구 목록 다시 불러오기
      await _loadFriends();
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
              onTap: () {
                Navigator.pop(context);
                _createOrNavigateToChatRoom(senderEmail, senderName);
              },
            ),
            if (!currentFriends.contains(senderEmail))
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('$senderName 님에게 친구 요청 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  _showSendFriendRequestForm(context, senderEmail);
                },
              ),
            if (currentFriends.contains(senderEmail))
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
        title: Text('여행 소모임'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedRegion,
            onChanged: (String? newValue) {
              setState(() {
                selectedRegion = newValue!;
              });
            },
            items: <String>['서울', '경기', '강원도', '경북', '경남', '전북', '전남', '충북', '충남', '제주도']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(selectedRegion).orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final documents = snapshot.data!.docs;
                return ListView(
                  children: documents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String message = data['message'] ?? '';
                    final String senderName = data['senderName'] ?? '';
                    final String senderUid = data['senderUid'] ?? '';
                    final String senderEmail = data['senderEmail'] ?? '';

                    final bool canDelete = currentUserId == senderUid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorFromEmail(senderEmail),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          _showOptions(context, senderEmail, senderName);
                        },
                        child: Text('$senderName: $message'),
                      ),
                      trailing: canDelete
                          ? IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteMessage(doc.id, selectedRegion);
                        },
                      )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 사용자: $senderName'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(labelText: '메시지 입력'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _sendMessage(_controller.text, selectedRegion);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String documentId, String region) {
    FirebaseFirestore.instance.collection(region).doc(documentId).delete().then((_) {
      print('메시지가 성공적으로 삭제되었습니다.');
    }).catchError((error) {
      print('메시지 삭제 중 오류가 발생했습니다: $error');
    });
  }

  void _sendMessage(String message, String region) {
    _controller.clear(); // 메시지를 전송한 후에 텍스트 필드를 지웁니다.
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email ?? '';
      FirebaseFirestore.instance.collection(region).add({
        'message': message,
        'senderName': senderName, // 사용자 이름 추가
        'senderUid': user.uid, // 사용자 UID 추가
        'senderEmail': userEmail, // 사용자 이메일 추가
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        print('메시지가 성공적으로 전송되었습니다.');
      }).catchError((error) {
        print('메시지 전송 중 오류가 발생했습니다: $error');
      });
    }
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
