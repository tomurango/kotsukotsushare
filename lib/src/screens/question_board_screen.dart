import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'question_input_screen.dart';
import '../providers/question_provider.dart';
import '../providers/answer_send_provider.dart';
import '../providers/answers_provider.dart';
import '../widgets/question/question_answers_list.dart';

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
    final questionState = ref.watch(questionsProvider);
    final isSubmitting = ref.watch(answerSubmitStateProvider);

    return questionState.when(
      data: (questionsData) {
        if (selectedQuestionScreen == 1) {
          return QuestionInputScreen();
        }
        if (questionsData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("質問がありません"),
              ],
            ),
          );
        }

        final validIndex = selectedQuestionIndex < questionsData.length ? selectedQuestionIndex : 0;
        if (selectedQuestionIndex >= questionsData.length) {
          Future.microtask(() =>
              ref.read(selectedQuestionIndexProvider.notifier).state = 0);
        }

        final questionId = questionsData[validIndex]["id"];

        final cachedAnswers = ref.watch(cachedAnswersProvider)[questionId] ?? [];

        final myAnswer = cachedAnswers.firstWhereOrNull((a) => a["isMine"] == true);
        final newText = myAnswer?["text"] ?? "";

        if (_answerController.text != newText) {
          _answerController.text = newText;
        }



        return SingleChildScrollView(
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

              // 🔥 送信ボタン
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (_answerController.text.trim().isEmpty) return;
                        final success = await ref
                            .read(answerSubmitProvider.notifier)
                            .submitAnswer(questionId, questionsData[validIndex]["question"],_answerController.text.trim());

                        if (success) {
                          // _answerController.clear();
                          final newAnswer = {
                            "text": _answerController.text.trim(),
                            "isMine": true,
                          };

                          // 今あるキャッシュを取得
                          final previousAnswers = ref.read(cachedAnswersProvider)[questionId] ?? [];

                          // 更新したリストを生成（すでに自分の回答があるなら上書き、なければ追加）
                          final updatedAnswers = [
                            ...previousAnswers.where((a) => a["isMine"] != true),
                            newAnswer,
                          ];

                          // キャッシュを更新
                          ref.read(cachedAnswersProvider.notifier).updateAnswers(questionId, updatedAnswers);
                          
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
                    : const Text("考えを質問者へ伝える"),
              ),
              const SizedBox(height: 16),

              // 🔥 回答リストを表示（別ウィジェット）
              QuestionAnswersList(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final errorMessage = error.toString().contains("質問がありません")
            ? "現在、質問がありません"
            : "エラーが発生しました";

        return Center(child: Text(errorMessage));
      },
    );
  }
}
