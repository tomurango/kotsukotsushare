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
  final FocusNode _answerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // フォーカス状態の変更を監視
    _answerFocusNode.addListener(() {
      ref.read(answerFieldFocusProvider.notifier).state = _answerFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _answerFocusNode.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final selectedQuestionScreen = ref.watch(selectedQuestionScreenProvider);
    final questionState = ref.watch(questionsProvider);
    final isSubmitting = ref.watch(answerSubmitStateProvider);

    // 質問が自分のものであるかどうか
    final questionsData = questionState.asData?.value ?? [];
    final isMine = questionsData.isNotEmpty && questionsData[selectedQuestionIndex]["type"] == "my";

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



        return GestureDetector(
          onTap: () {
            // 画面の空白部分をタップしたときにフォーカスを外す
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // チャットUIスタイル：自分の質問は右寄せ、他人は左寄せ
              Align(
                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMine) Icon(Icons.person, size: 18, color: Colors.green[700]),
                        if (isMine) SizedBox(width: 4),
                        Text(
                          isMine ? "あなたの質問:" : "質問:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isMine ? Colors.green[700] : Colors.black,
                          ),
                        ),
                        if (!isMine) SizedBox(width: 4),
                        if (!isMine) Icon(Icons.help_outline, size: 18, color: Colors.grey[700]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMine ? Color(0xFFDCF8C6) : Colors.grey[200], // 自分:緑、他人:灰色
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        questionsData[validIndex]["question"] ?? "質問なし",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 自分の質問か他人の質問かで表示を変える
              Row(
                children: [
                  Icon(
                    isMine ? Icons.edit_note : Icons.reply,
                    size: 20,
                    color: isMine ? Colors.green[700] : Colors.blue[700],
                  ),
                  SizedBox(width: 6),
                  Text(
                    isMine ? "自分のメモ:" : "あなたの回答:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMine ? Colors.green[700] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: isMine ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMine ? Colors.green[200]! : Colors.blue[200]!,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _answerController,
                  focusNode: _answerFocusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: isMine
                        ? "この質問に対する自分の考えをメモしましょう"
                        : "質問者に伝えたい考えを書きましょう",
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 12),

              // 送信ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                              SnackBar(
                                content: Text(isMine ? "メモを記録しました！" : "回答を送信しました！"),
                                backgroundColor: isMine ? Colors.green : Colors.blue,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("送信に失敗しました")),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(isMine ? Icons.save : Icons.send),
                  label: Text(
                    isMine ? "自分の考えを記録する" : "考えを質問者へ伝える",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMine ? Colors.green[600] : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔥 回答リストを表示（別ウィジェット）
              QuestionAnswersList(),
            ],
          ),
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
