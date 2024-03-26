import 'package:flutter/material.dart';
import '../main.dart';

class SignUpPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isAllFieldsFilled() {
    return nameController.text.isNotEmpty &&
        idController.text.isNotEmpty &&
        phoneNumberController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  bool _validateId(String id) {
    return id.length >= 6;
  }

  bool _validatePassword(String password) {
    return password.length >= 4;
  }

  bool _validatePhoneNumber(String phoneNumber) {
    // 전화번호가 "010-1234-5678"과 같은 형식인지 확인
    RegExp phoneNumberRegExp = RegExp(r'^\d{3}-\d{4}-\d{4}$');
    return phoneNumberRegExp.hasMatch(phoneNumber);
  }

  void _signUp(BuildContext context) {
    if (_isAllFieldsFilled()) {
      String enteredId = idController.text;
      String enteredPassword = passwordController.text;
      String enteredPhoneNumber = phoneNumberController.text;

      if (_validateId(enteredId) &&
          _validatePassword(enteredPassword) &&
          _validatePhoneNumber(enteredPhoneNumber)) {
        // 모든 조건을 만족하면 회원가입 완료
        print('회원가입 완료!');

        // 메인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      } else {
        // 조건을 만족하지 않으면 에러 메시지 출력
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('오류'),
              content: Text('아이디는 6자 이상, 비밀번호는 4자 이상이어야 하며, 전화번호는 "010-1234-5678" 형식이어야 합니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // 필드 중 하나라도 비어있을 경우 에러 메시지 출력
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('오류'),
            content: Text('비어있는 칸을 입력하세요'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이름', style: TextStyle(fontSize: 16),),
                  TextField(controller: nameController,
                    decoration: InputDecoration(hintText: '이름을 입력하세요',),),
                  SizedBox(height: 20),

                  Text('아이디', style: TextStyle(fontSize: 16),),
                  TextField(controller: idController,
                    decoration: InputDecoration(hintText: '아이디를 입력하세요',),),
                  SizedBox(height: 20),

                  Text('비밀번호', style: TextStyle(fontSize: 16),),
                  TextField(controller: passwordController,
                    decoration: InputDecoration(hintText: '비밀번호를 입력하세요',), obscureText: true,),
                  SizedBox(height: 20),

                  Text('전화번호', style: TextStyle(fontSize: 16),),
                  TextField(controller: phoneNumberController,
                    decoration: InputDecoration(hintText: '전화번호를 입력하세요',),),
                  SizedBox(height: 40),


                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _signUp(context); // 회원가입 함수 호출
                      },
                      child: Text('회원가입'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
