import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'tutorial_screen.dart';
import 'how_to_use_screen.dart';
import 'subscription_screen.dart';
import '../providers/subscription_status_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  final Function(int) onNavigate;
  SettingsScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isPremium = ref.watch(subscriptionStatusProvider);

    return ListView(
      children: [
        // ユーザープランの確認と購入画面への遷移
        ListTile(
          leading: Icon(Icons.subscriptions),
          title: Text(
            isPremium ? '現在のプラン: Premium' : '現在のプラン: Free',
          ),
          //title: Text('現在のプラン: $userPlan'),
          subtitle: Text(isPremium ? 'プレミアムプランをご利用中です' : 'プレミアムプランを購入できます'),
          onTap: () {
            if (!isPremium) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SubscriptionScreen(),
                ),
              );
            } else if (isPremium) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("すでにプレミアムプランをご利用中です")),
              );
            }
          },
        ),
        Divider(
          height: 0,
        ),
        // チュートリアル再表示
        ListTile(
          leading: Icon(Icons.flag),
          title: Text('アプリの基本理念を再確認'),
          subtitle: Text('アプリの目指す価値や考え方をもう一度振り返ることができます'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TutorialScreen(),
              ),
            );
          },
        ),
        Divider(
          height: 0,
        ),
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
        Divider(
          height: 0,
        ),
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
        Divider(
          height: 0,
        ),
        // アカウント削除
        ListTile(
          leading: Icon(Icons.delete),
          title: Text('アカウント削除'),
          subtitle: Text('アカウントを削除します'),
          onTap: () {
            _deleteAccount(context);
          },
        ),
        Divider(
          height: 0,
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
