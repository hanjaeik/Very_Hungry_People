import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/schedule_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomTitle;
  final String chatRoomId;

  ChatRoomPage({required this.chatRoomTitle, required this.chatRoomId});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  String? currentUserEmail;
  Set<String> friendsEmails = {};

  @override
  void initState() {
    super.initState();
    currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (currentUserEmail == null) return;

    var friendsSnapshot = await FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUserEmail)
        .collection('friends')
        .get();

    setState(() {
      friendsEmails = friendsSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _deleteFriend(String friendEmail) async {
    if (currentUserEmail == null) return;

    await FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUserEmail)
        .collection('friends')
        .doc(friendEmail)
        .delete();

    await FirebaseFirestore.instance
        .collection('friends')
        .doc(friendEmail)
        .collection('friends')
        .doc(currentUserEmail)
        .delete();

    setState(() {
      friendsEmails.remove(friendEmail);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('친구가 삭제되었습니다.'),
    ));
  }

  void _sendMessage(String chatRoomId) async {
    String message = _messageController.text;
    if (message.isEmpty) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).collection('messages').add({
      'text': message,
      'sender': user.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
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
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('userpf')
        .where('name', isEqualTo: userName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  Future<bool> _isUserPrivate(String email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('userSettings').doc(email).get();
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

  Future<String> _findUserNameByEmail(String email) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('userpf').doc(email).get();
    if (userSnapshot.exists) {
      return (userSnapshot.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
    }
    return 'Unknown';
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, 'refresh');
          },
        ),
        title: Text(widget.chatRoomTitle),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['sender'] == currentUserEmail;
                    return GestureDetector(
                      onLongPress: () async {
                        String senderName = await _findUserNameByEmail(message['sender']);
                        _showOptions(context, message['sender'], senderName);
                      },
                      child: _buildMessageBubble(message, isCurrentUser),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지 입력',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(widget.chatRoomId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentUser)
            GestureDetector(
              onTap: () async {
                String senderName = await _findUserNameByEmail(message['sender']);
                _showOptions(context, message['sender'], senderName);
              },
              child: CircleAvatar(
                backgroundColor: _getColorFromEmail(message['sender']),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.lightBlue[200] : Colors.grey[300],
              borderRadius: isCurrentUser
                  ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
              )
                  : BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
            ),
            child: Text(
              message['text'],
              style: TextStyle(color: Colors.black87),
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
