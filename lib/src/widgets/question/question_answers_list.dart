import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/answers_provider.dart';
import '../../providers/question_provider.dart';

class QuestionAnswersList extends HookConsumerWidget {
  const QuestionAnswersList({Key? key}) : super(key: key); // ✅ questionId を削除

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final questionListAsync = ref.watch(questionsProvider);

    return questionListAsync.when(
      data: (questions) {
        if (selectedQuestionIndex >= questions.length) {
          return const Center(child: Text("無効な質問が選択されています"));
        }

        final questionId = questions[selectedQuestionIndex]["id"];
        final questionIsMine = questions[selectedQuestionIndex]["type"] == "my";

        final answersState = ref.watch(answersProvider(questionId));
        final cachedAnswers = ref.watch(cachedAnswersProvider)[questionId] ?? [];

        // ✅ Cloud Functions の取得完了後、キャッシュに反映
        useEffect(() {
          ref.listen(answersProvider(questionId), (previous, next) {
            next.whenData((answers) {
              ref.read(cachedAnswersProvider.notifier).updateAnswers(questionId, answers);
            });
          });
          return null;
        }, [questionId]);

        // ✅ 表示ロジック：キャッシュベースで描画
        if (cachedAnswers.isEmpty && answersState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cachedAnswers.isEmpty && answersState.hasError) {
          return Center(child: Text("エラーが発生しました: ${answersState.error}"));
        }

        // 質問が自分のものでない場合、自分で投稿した質問なら他の人の回答が見れることを伝えるメッセージを表示
        if (!questionIsMine) {
          return const Center(child: Text("自分で投稿した質問のみ、他の誰かの考えを確認できます"));
        }

        if (cachedAnswers.isEmpty) {
          return const Center(child: Text("まだ回答がありません"));
        }

        if (cachedAnswers.length == 1 && cachedAnswers[0]["isMine"] == true) {
          // 自分の回答しかない場合
          return const Center(child: Text("他の人の回答はまだありません"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cachedAnswers.length,
          itemBuilder: (context, index) {
            final answer = cachedAnswers[index];
            // 自分の回答かどうかを判定
            final isMine = answer["isMine"] == true;
            // 自分の回答の場合、表示しない
            if (isMine) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answer["text"] ?? "",
                style: const TextStyle(fontSize: 16),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("質問の取得に失敗しました: $e")),
    );
  }
}
