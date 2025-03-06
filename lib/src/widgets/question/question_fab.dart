import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_provider.dart';

class QuestionFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        ref.read(selectedQuestionScreenProvider.notifier).state = 1; // 質問入力画面に切り替え
      },
      icon: Icon(Icons.add, color: Colors.white), // 🔹 アイコンの色も統一
      label: Text(
        "質問を投稿する",
        style: TextStyle(color: Colors.white), // 🔥 文字色を白に変更
      ),
      backgroundColor: Color(0xFF008080), // 🔹 ボタンの背景色
      foregroundColor: Colors.white, // 🔥 文字色（デフォルトのテキストとアイコン）
    );
  }
}
