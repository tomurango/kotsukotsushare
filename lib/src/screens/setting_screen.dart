import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  final Function(int) onNavigate;
  SettingsScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      children: [
        // サインアウト
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('サインアウト'),
          subtitle: Text('現在ログインしているメールアドレス (${user?.email ?? ''}) からサインアウトします'),
          onTap: () {
            // サインアウト確認ダイアログを表示
            _showSignOutDialog(context);
          },
        ),
        Divider(),
        // お問い合わせ、利用規約、プライバシーポリシー
        ListTile(
          leading: Icon(Icons.contact_page),
          title: Text('お問い合わせ、利用規約、プライバシーポリシー'),
          subtitle: Text('https://chokushii.com/contact へ遷移します'),
          onTap: () async {
            const url = 'https://chokushii.com/contact';
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              throw 'Could not launch $url';
            }
          },
        ),
      ],
    );
  }

  // サインアウト確認ダイアログを表示
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('サインアウト確認'),
          content: Text('本当にサインアウトしますか？'),
          actions: [
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
            ),
            TextButton(
              child: Text('サインアウト'),
              onPressed: () {
                FirebaseAuth.instance.signOut(); // サインアウト処理
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
            ),
          ],
        );
      },
    );
  }
}
