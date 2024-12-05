import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/login_page/login_or_register_page.dart';
import '/center_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData) {
            return StartPage();
          } else {
            return LoginOrRegisterPage();
          }
        }
      },
    );
  }
}
