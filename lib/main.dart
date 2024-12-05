import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import '/user_setting.dart';
import '/ThemeManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDDbUt2MZGGFgYt26_NuuxeVcu72lYXrZA",
      authDomain: "YOUR_AUTH_DOMAIN",
      projectId: "ekffur-acf36",
      storageBucket: "YOUR_STORAGE_BUCKET",
      messagingSenderId: "1087247374379",
      appId: "1:1087247374379:android:9043e9755d3b9d2deeb26e",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>(create: (_) => ThemeManager()),
        ChangeNotifierProvider<UserSettings>(create: (_) => UserSettings()), // UserSettings Provider 추가
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '스케줄 조율 앱',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              // 라이트 모드 테마 설정
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              // 다크 모드 테마 설정
            ),
            themeMode: themeManager.themeMode, // ThemeManager의 themeMode 사용
            home: AuthPage(),
          );
        },
      ),
    );
  }
}
