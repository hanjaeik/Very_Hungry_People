import 'package:flutter/material.dart';
import 'sign_up.dart';
import '../main.dart'; // 추가

void main() {
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Lsogin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _idController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isIdValid = true;
  bool _isPasswordValid = true;

  void _login() {
    // 입력된 아이디와 비밀번호
    String enteredId = _idController.text;
    String enteredPassword = _passwordController.text;

    // 아이디와 비밀번호가 올바르게 입력되었는지 확인
    bool isValidId = _validateId(enteredId);
    bool isValidPassword = _validatePassword(enteredPassword);

    if (isValidId && isValidPassword) {
      // 올바르게 입력되었을 때 로그인 처리
      print('로그인 성공! 아이디: $enteredId, 비밀번호: $enteredPassword');

      // 로그인 성공 시 MainPage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()), // MainPage로 이동
      );
    } else {
      // 입력이 올바르지 않을 때 에러 메시지 표시
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('에러'),
            content: Text('아이디와 비밀번호를 올바르게 입력해주세요.'),
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

// 아이디 유효성 검사 함수
  bool _validateId(String id) {
    // 여기에 아이디의 유효성 검사 로직을 작성합니다.
    // 예를 들어, 아이디가 특정 양식에 맞지 않으면 false를 반환합니다.
    // 이 예시에서는 길이가 4자 이상이어야 유효한 것으로 가정합니다.
    return id.length >= 4;
  }

// 비밀번호 유효성 검사 함수
  bool _validatePassword(String password) {
    // 여기에 비밀번호의 유효성 검사 로직을 작성합니다.
    // 예를 들어, 비밀번호가 특정 조건을 충족하지 않으면 false를 반환합니다.
    // 이 예시에서는 길이가 6자 이상이어야 유효한 것으로 가정합니다.
    return password.length >= 6;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
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
                  Text('아이디', style: TextStyle(fontSize: 16),),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(hintText: '아이디를 입력하세요',),),
                  SizedBox(height: 20),

                  Text('비밀번호', style: TextStyle(fontSize: 16),),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(hintText: '비밀번호를 입력하세요',), obscureText: true,),
                  SizedBox(height: 40),


                  Center(
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text('로그인'),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // 비밀번호 찾기
                  },
                  child: Text('비밀번호 찾기'),
                ),
                TextButton(
                  onPressed: () {
                    // 아이디 찾기
                  },
                  child: Text('아이디 찾기'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
