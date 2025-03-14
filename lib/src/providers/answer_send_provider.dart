import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// 🔥 送信状態の管理
final answerSubmitStateProvider = StateProvider<bool>((ref) => false);

// 🔥 回答の送信を管理する Notifier
class AnswerSubmitNotifier extends StateNotifier<bool> {
  AnswerSubmitNotifier() : super(false);

  Future<bool> submitAnswer(String questionId, String answerText) async {
    state = true; // 🔥 送信中状態にする
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addAnswer');
      await callable.call({"questionId": questionId, "answerText": answerText});
      return true; // 🔥 成功
    } catch (e) {
      print("❌ 回答の送信に失敗: $e");
      return false; // 🔥 失敗
    } finally {
      state = false; // 🔥 送信完了
    }
  }
}

// 🔥 回答の送信プロバイダー
final answerSubmitProvider = StateNotifierProvider<AnswerSubmitNotifier, bool>((ref) {
  return AnswerSubmitNotifier();
});
