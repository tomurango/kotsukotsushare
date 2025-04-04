import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// 🔹 ダミーデータ（mock data）
final List<Map<String, dynamic>> mockQuestions = [
  {"id": "hoge1", "question": "Flutterで状態管理は何が良い？", "type": "random"},
  {"id": "hoge2", "question": "Riverpodのメリットは？", "type": "my"},
  {"id": "hoge3", "question": "Firebaseを使うときの注意点は？", "type": "my"},
  {"id": "hoge4", "question": "Dartの非同期処理の書き方は？", "type": "my"},
  {"id": "hoge5", "question": "Flutterでのアニメーションの作り方は？", "type": "favorite"},
  {"id": "hoge6", "question": "BLoCパターンのメリットは？", "type": "favorite"},
  {"id": "hoge7", "question": "RiverpodとProviderの違いは？", "type": "favorite"},
];

// 🔹 空のダミーデータ（質問なし）
final List<Map<String, dynamic>> emptyMockQuestions = [];

// ✅ Mock Provider（常にダミーデータを返す）
final questionsMockProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(Duration(milliseconds: 500)); // 🔹 500ms の遅延を入れる（実際の API に近づける）
  return mockQuestions;
});

final questionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final callable = FirebaseFunctions.instance.httpsCallable('getQuestions');
  final response = await callable.call();

  // 🔥 `List<Object?>` から `List<Map<String, dynamic>>` に変換
  List<Map<String, dynamic>> convertedData = [];

  for (var item in response.data) {
    if (item is Map) {
      final convertedItem = Map<String, dynamic>.from(item);
      convertedData.add(convertedItem);
    } else {
      print("❌ Unexpected item type: ${item.runtimeType} - $item");
    }
  }

  return convertedData;
});

// 選択中の質問のインデックス
final selectedQuestionIndexProvider = StateProvider<int>((ref) => 0);

// BottomSheet の開閉状態
final isExpandedProvider = StateProvider<bool>((ref) => false);

// 表示する画面の状態を管理するProvider
final selectedQuestionScreenProvider = StateProvider((ref) => 0); // 0: 質問一覧, 1: 質問入力画面
