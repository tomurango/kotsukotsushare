import 'package:flutter/material.dart';

class QuestionFAB extends StatelessWidget {
  final void Function(int) onNavigate;

  QuestionFAB({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        onNavigate(1); // 質問作成画面へ遷移
      },
      icon: Icon(Icons.add),
      label: Text("質問を投稿する"),
      backgroundColor: Color(0xFF008080),
    );
  }
}
