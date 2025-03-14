import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/answers_provider.dart';

class QuestionAnswersList extends ConsumerWidget {
  final String questionId;

  QuestionAnswersList({required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answersState = ref.watch(answersProvider(questionId));
    final cachedAnswers = ref.watch(cachedAnswersProvider)[questionId] ?? [];

    ref.listen(answersProvider(questionId), (previous, next) {
      next.whenData((answers) {
        ref.read(cachedAnswersProvider.notifier).updateAnswers(questionId, answers);
      });
    });

    return answersState.when(
      data: (answers) {
        if (answers.isEmpty) {
          return const Center(child: Text("まだ回答がありません"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: answers.length,
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answers[index]["text"],
                style: TextStyle(fontSize: 16),
              ),
            );
          },
        );
      },
      loading: () => cachedAnswers.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cachedAnswers.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cachedAnswers[index]["text"],
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("エラーが発生しました: $e")),
    );
  }
}
