import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'answer_send_provider.dart';
import 'question_provider.dart';
import 'answers_provider.dart';

void resetAppState(WidgetRef ref) {
  ref.invalidate(questionsProvider);
  ref.invalidate(cachedAnswersProvider);
  ref.invalidate(answersProvider);
  ref.invalidate(selectedQuestionIndexProvider);
  ref.invalidate(isExpandedProvider);
  ref.invalidate(selectedQuestionScreenProvider);
  ref.invalidate(answerSubmitStateProvider);
  ref.invalidate(answerSubmitProvider);

  // 必要なら他の Provider もここで無効化
}
