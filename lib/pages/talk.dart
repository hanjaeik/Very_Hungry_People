import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/Friends_Matching.dart';
import '/pages/chat_room.dart';
import '/pages/schedule_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스케줄 조율앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatListPage(),
    );
  }
}

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> friendsEmails = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var friendsSnapshot = await _firestore
        .collection('friends')
        .doc(user.email)
        .collection('friends')
        .get();

    setState(() {
      friendsEmails = friendsSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _createChatRoom(String friendName, String friendEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String currentUserEmail = user.email ?? 'unknown';
    String chatRoomId = _getChatRoomId(currentUserEmail, friendEmail);

    DocumentSnapshot chatRoomSnapshot = await _firestore.collection('chatRooms').doc(chatRoomId).get();

    if (!chatRoomSnapshot.exists) {
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'members': [currentUserEmail, friendEmail],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(chatRoomTitle: '$friendName님과의 대화', chatRoomId: chatRoomId),
      ),
    );

    if (result == 'refresh') {
      setState(() {
        // setState를 호출하여 UI를 다시 빌드하고 메시지 목록을 다시 불러옴
      });
    }
  }

  Future<void> _deleteChatRoom(String chatRoomId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('채팅방이 삭제되었습니다.'),
    ));
  }

  Future<void> _deleteFriend(String friendEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userEmail = user.email!;

      // 친구 관계를 삭제
      await _firestore.collection('friends').doc(userEmail).collection('friends').doc(friendEmail).delete();
      await _firestore.collection('friends').doc(friendEmail).collection('friends').doc(userEmail).delete();

      // 친구 목록 다시 불러오기
      await _loadFriends();

      // 친구 삭제 알림
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구가 삭제되었습니다.'),
      ));
    }
  }

  String _getChatRoomId(String email1, String email2) {
    List<String> emails = [email1, email2];
    emails.sort();
    return emails.join('_');
  }

  void _showOptions(BuildContext context, String senderEmail, String senderName) async {
    bool isPrivate = await _isUserPrivate(senderEmail);
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
            if (!isPrivate)
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
            if (!friendsEmails.contains(senderEmail))
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('$senderName님에게 친구 요청 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  _showSendFriendRequestForm(context, senderEmail);
                },
              ),
            if (friendsEmails.contains(senderEmail))
              ListTile(
                leading: Icon(Icons.person_remove),
                title: Text('$senderName님 친구 삭제'),
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

  Future<String?> _findUserEmailByName(String userName) async {
    QuerySnapshot snapshot = await _firestore
        .collection('userpf')
        .where('name', isEqualTo: userName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  Future<bool> _isUserPrivate(String email) async {
    DocumentSnapshot userDoc = await _firestore.collection('userSettings').doc(email).get();
    return userDoc.exists && (userDoc['isPrivate'] ?? false);
  }

  void _showSendFriendRequestForm(BuildContext context, String recipientEmail) {
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
              Text('친구 요청 보내기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _friendRequestController,
                decoration: InputDecoration(
                  labelText: '이메일 입력',
                  hintText: recipientEmail,
                ),
              ),
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
      await _firestore.collection('friend_requests').add({
        'senderEmail': senderEmail,
        'recipientEmail': recipientEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구 요청이 성공적으로 전송되었습니다.'),
      ));
    }
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
        title: Text('채팅'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsMatchingPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser == null
            ? Stream.empty()
            : _firestore
            .collection('chatRooms')
            .where('members', arrayContains: FirebaseAuth.instance.currentUser?.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final chatRoomData = chatRoom.data() as Map<String, dynamic>?;

              if (chatRoomData == null || !chatRoomData.containsKey('members')) {
                return ListTile(
                  title: Text('제목 없음'),
                  subtitle: Text('채팅방 설명'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatRoomTitle: '제목 없음',
                          chatRoomId: chatRoom.id,
                        ),
                      ),
                    );
                  },
                );
              }

              List<String> members = List<String>.from(chatRoomData['members']);
              String friendEmail = members.firstWhere((email) => email != FirebaseAuth.instance.currentUser?.email, orElse: () => '');

              if (friendEmail.isEmpty) {
                return Container(); // Skip if friendEmail is empty
              }

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('userpf').doc(friendEmail).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('불러오는 중...'),
                      subtitle: Text('채팅방 설명'),
                    );
                  }

                  final friendData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final friendName = friendData?['name'] ?? '알 수 없는 사용자';

                  return FutureBuilder<QuerySnapshot>(
                    future: _firestore
                        .collection('chatRooms')
                        .doc(chatRoom.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .get(),
                    builder: (context, messageSnapshot) {
                      if (!messageSnapshot.hasData) {
                        return ListTile(
                          title: Text(friendName),
                          subtitle: Text('마지막 메시지를 불러오는 중...'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomPage(
                                  chatRoomTitle: '$friendName님과의 대화',
                                  chatRoomId: chatRoom.id,
                                ),
                              ),
                            );
                          },
                        );
                      }

                      final lastMessage = messageSnapshot.data!.docs.isNotEmpty
                          ? messageSnapshot.data!.docs.first['text']
                          : '메시지가 없습니다';

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            _showOptions(context, friendEmail, friendName);
                          },
                          child: CircleAvatar(
                            backgroundColor: _getColorFromEmail(friendEmail),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        title: Text(friendName),
                        subtitle: Text(lastMessage),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomPage(
                                chatRoomTitle: '$friendName님과의 대화',
                                chatRoomId: chatRoom.id,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteChatRoom(chatRoom.id);
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
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
      backgroundColor: Colors.yellow[100], // 여기서 배경색을 연한 노랑색
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
