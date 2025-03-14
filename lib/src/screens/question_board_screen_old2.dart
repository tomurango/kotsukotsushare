import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'question_input_screen.dart';
import '../providers/question_provider.dart';
import '../providers/answer_send_provider.dart';

class QuestionBoardScreen extends ConsumerStatefulWidget {
  final void Function(int) onNavigate;

  QuestionBoardScreen({required this.onNavigate});

  @override
  _QuestionBoardScreenState createState() => _QuestionBoardScreenState();
}

class _QuestionBoardScreenState extends ConsumerState<QuestionBoardScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final selectedQuestionScreen = ref.watch(selectedQuestionScreenProvider);
    final questionState = ref.watch(questionsProvider); // ✅ `FutureProvider` を watch
    final isSubmitting = ref.watch(answerSubmitStateProvider); // 🔥 送信状態を監視

    return Scaffold(
      body: questionState.when(
        data: (questionsData) {
          if (questionsData.isEmpty) {
            return selectedQuestionScreen == 0
                ? const Center(child: Text("現在、質問がありません"))
                : QuestionInputScreen();
          }

          // ✅ `selectedQuestionIndex` が範囲外ならリセット
          final validIndex = selectedQuestionIndex < questionsData.length ? selectedQuestionIndex : 0;
          if (selectedQuestionIndex >= questionsData.length) {
            Future.microtask(() =>
                ref.read(selectedQuestionIndexProvider.notifier).state = 0);
          }

          final questionId = questionsData[validIndex]["id"];

          return selectedQuestionScreen == 0
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "質問:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          questionsData[validIndex]["question"] ?? "質問なし",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "あなたの考え:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _answerController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "あなたの考えを教えてください",
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // 🔥 送信ボタンを追加
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_answerController.text.trim().isEmpty) return;
                                final success = await ref
                                    .read(answerSubmitProvider.notifier)
                                    .submitAnswer(questionId, _answerController.text.trim());

                                if (success) {
                                  _answerController.clear(); // ✅ 成功したら入力欄をクリア
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("回答を送信しました！")),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("送信に失敗しました")),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("回答を送信"),
                      ),
                    ],
                  ),
                )
              : QuestionInputScreen();
        },
        loading: () => const Center(child: CircularProgressIndicator()), // ✅ ローディング処理
        error: (error, _) {
          final errorMessage = error.toString().contains("質問がありません")
              ? "現在、質問がありません"
              : "エラーが発生しました";

          return Center(child: Text(errorMessage));
        },
      ),
    );
  }
}
