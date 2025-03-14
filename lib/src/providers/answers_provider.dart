import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// 🔥 質問ごとに回答を取得する `FutureProvider.family`
final answersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, questionId) async {
  final callable = FirebaseFunctions.instance.httpsCallable('getAnswers');
  final response = await callable.call({"questionId": questionId});

  // 🔥 Cloud Functions から受け取ったデータを `List<Map<String, dynamic>>` に変換
  List<Map<String, dynamic>> convertedData = [];

  for (var item in response.data["answers"]) {
    if (item is Map) {
      final convertedItem = Map<String, dynamic>.from(item);
      convertedData.add(convertedItem);
    } else {
      print("❌ Unexpected item type: ${item.runtimeType} - $item");
    }
  }

  return convertedData;
});

// 🔥 回答データをキャッシュするための `StateNotifier`
class CachedAnswersNotifier extends StateNotifier<Map<String, List<Map<String, dynamic>>>> {
  CachedAnswersNotifier() : super({});

  // 🔥 キャッシュを更新する関数
  void updateAnswers(String questionId, List<Map<String, dynamic>> answers) {
    state = {...state, questionId: answers};
  }
}

// 🔥 キャッシュ付きの回答 Provider
final cachedAnswersProvider = StateNotifierProvider<CachedAnswersNotifier, Map<String, List<Map<String, dynamic>>>>((ref) {
  return CachedAnswersNotifier();
});
