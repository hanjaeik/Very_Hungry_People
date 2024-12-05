import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        title: Text('내 프로필'),
      ),
      body: Center(
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Text('로그인 정보를 가져오는 중에 오류가 발생했습니다.');
            }

            final currentUser = snapshot.data!;
            final userEmail = currentUser.email;

            if (userEmail == null) {
              return Text('사용자 이메일을 찾을 수 없습니다.');
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('userpf').doc(userEmail).snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('오류가 발생했습니다: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text('사용자 정보가 없습니다.');
                }

                final userInfo = snapshot.data!.data() as Map<String, dynamic>;

                return ProfileWidget(
                  name: userInfo['name'] ?? '',
                  phoneNumber: userInfo['phoneNumber'] ?? '',
                  age: userInfo['age'] ?? '',
                  gender: userInfo['gender'] ?? '',
                  email: userEmail,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ProfileWidget extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String age;
  final String gender;
  final String email;

  ProfileWidget({
    required this.name,
    required this.phoneNumber,
    required this.age,
    required this.gender,
    required this.email,
  });

  Color _getColorFromEmail(String email) {
    final hash = email.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: Offset(-10, -60),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                '이름: $name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '전화번호: $phoneNumber',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                '나이: $age',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                '성별: $gender',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
