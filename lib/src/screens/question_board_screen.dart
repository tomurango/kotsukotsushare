import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'question_input_screen.dart';
import '../providers/question_provider.dart';

class QuestionBoardScreen extends ConsumerWidget {
  final void Function(int) onNavigate;
  
  QuestionBoardScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final questions = ref.watch(questionsProvider);
    final selectedQuestionScreen = ref.watch(selectedQuestionScreenProvider); // 画面の状態を取得

    // 選択中の質問が範囲外の場合は 0 にリセット
    if (selectedQuestionIndex >= questions.length) {
      Future.microtask(() => ref.read(selectedQuestionIndexProvider.notifier).state = 0);
    }

    return Scaffold(
    body: selectedQuestionScreen == 0
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                "質問:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    questions[selectedQuestionIndex]["question"] ?? "質問なし",
                    style: TextStyle(fontSize: 16),
                ),
                ),
                SizedBox(height: 16),
                Text(
                "解答:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "解答を入力してください",
                ),
                maxLines: 3,
                ),
            ],
            ),
        )
        : QuestionInputScreen(),
    );
  }
}
