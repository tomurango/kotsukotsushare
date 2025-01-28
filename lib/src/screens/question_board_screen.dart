import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionBoardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  QuestionBoardScreen({required this.onNavigate});

  // リンクを開く関数
  Future<void> _openLink(String url, BuildContext context) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リンクを開けませんでした: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'ただいま質問掲示板を準備中です。',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openLink(
                'https://x.com/chokushii', context), // ここにリンクのURLを入力
            child: const Text(
              'ご意見・ご要望はこちらまで（X、旧Twitter）',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
