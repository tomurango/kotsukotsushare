import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutorial_screen.dart';
import 'how_to_use_screen.dart';

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
        Divider(),
        // アカウント削除
        ListTile(
          leading: Icon(Icons.delete),
          title: Text('アカウント削除'),
          subtitle: Text('アカウントを削除します'),
          onTap: () {
            _deleteAccount(context);
          },
        ),
        /*
        Divider(),
        // チュートリアル再表示
        ListTile(
          leading: Icon(Icons.help),
          title: Text('チュートリアルを再表示'),
          subtitle: Text('アプリのチュートリアルを再度確認します'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TutorialScreen(),
              ),
            );
          },
        ),*/
        Divider(),
        // アプリの使い方
        ListTile(
          leading: Icon(Icons.help),
          title: Text('アプリの使い方'),
          subtitle: Text('アプリの使い方を確認します'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HowToUseScreen(),
              ),
            );
          },
        ),
        Divider(),
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

  // アカウント削除処理
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ログインされていません。")));
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("アカウント削除の確認"),
          content: Text("アカウントを削除すると復元できません。本当に削除しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("削除"),
            ),
          ],
        );
      },
    );

    if (!confirmDelete) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("アカウントが削除されました。")));
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("アカウント削除に失敗しました: $e")));
    }
  }
}
