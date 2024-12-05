import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/ThemeManager.dart';
import '/user_setting.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('환경설정'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('다크 모드', style: Theme.of(context).textTheme.bodyText1),
            value: Provider.of<ThemeManager>(context).isDarkMode,
            onChanged: (value) {
              Provider.of<ThemeManager>(context, listen: false).toggleTheme(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(value ? '다크 모드가 활성화되었습니다.' : '다크 모드가 비활성화되었습니다.')),
              );
            },
            secondary: Icon(Icons.brightness_6, color: Theme.of(context).iconTheme.color),
          ),
          SwitchListTile(
            title: Text('알람 설정', style: Theme.of(context).textTheme.bodyText1),
            value: false, // 현재 설정되어 있는 알람 상태에 따라서 true 또는 false로 설정되어야 합니다.
            onChanged: (value) {
              // 알람 설정 변경
            },
            secondary: Icon(Icons.alarm, color: Theme.of(context).iconTheme.color),
          ),
          SwitchListTile(
            title: Text('내 정보 공유하지 않기', style: Theme.of(context).textTheme.bodyText1),
            value: Provider.of<UserSettings>(context).isPrivate, // 사용자 설정 값 불러오기
            onChanged: (value) {
              Provider.of<UserSettings>(context, listen: false).togglePrivacy(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(value ? '내 정보가 비공개로 설정되었습니다.' : '내 정보가 공개로 설정되었습니다.')),
              );
            },
            secondary: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
          ),
          ListTile(
            title: Text(
              '언어 설정',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            subtitle: Text(
              '한국어',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            onTap: () {
              // 언어 설정 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LanguageSettingsPage()),
              );
            },
            leading: Icon(Icons.language, color: Theme.of(context).iconTheme.color),
          ),
          ListTile(
            title: Text(
              '만든 사람들',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            onTap: () {
              // 만든 사람들 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreditsPage()),
              );
            },
            leading: Icon(Icons.people, color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('언어 설정'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('한국어'),
            onTap: () {
              // 한국어로 언어 변경
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('한국어로 변경되었습니다.')));
              // 한국어로 언어 변경하는 코드 작성
            },
          ),
          ListTile(
            title: Text('English'),
            onTap: () {
              // 영어로 언어 변경
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('English로 변경되었습니다.')));
              // 영어로 언어 변경하는 코드 작성
            },
          ),
          // 추가적인 언어 항목을 필요에 따라서 추가할 수 있습니다.
        ],
      ),
    );
  }
}

class CreditsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('만든 사람들'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('권혁준'),
            subtitle: Text('루피'),
          ),
          ListTile(
            title: Text('한재익'),
            subtitle: Text('거인'),
          ),
          ListTile(
            title: Text('시종범'),
            subtitle: Text('짱구'),
          ),
          ListTile(
            title: Text('이근재'),
            subtitle: Text('빅맘'),
          ),
          ListTile(
            title: Text('김가현'),
            subtitle: Text('맹구'),
          ),
          // 추가적인 개발자 항목을 필요에 따라서 추가할 수 있습니다.
        ],
      ),
    );
  }
}
