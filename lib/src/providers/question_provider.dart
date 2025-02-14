import 'package:flutter_riverpod/flutter_riverpod.dart';

// 共通の質問リスト
final questionsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {"question": "Flutterで状態管理は何が良い？", "type": "public"},
    {"question": "Riverpodのメリットは？", "type": "public"},
    {"question": "Firebaseを使うときの注意点は？", "type": "public"},
    {"question": "Dartの非同期処理の書き方は？", "type": "public"},
    {"question": "Flutterでのアニメーションの作り方は？", "type": "public"},
    {"question": "BLoCパターンのメリットは？", "type": "private"},
    {"question": "RiverpodとProviderの違いは？", "type": "private"},
  ];
});

// 選択中の質問のインデックス
final selectedQuestionIndexProvider = StateProvider<int>((ref) => 0);

// BottomSheet の開閉状態
final isExpandedProvider = StateProvider<bool>((ref) => false);

// 自分の質問の表示トグル
final showMyQuestionsProvider = StateProvider<bool>((ref) => true);

// みんなの質問の表示トグル
final showAllQuestionsProvider = StateProvider<bool>((ref) => true);

// 表示する画面の状態を管理するProvider
final selectedQuestionScreenProvider = StateProvider((ref) => 0); // 0: 質問一覧, 1: 質問入力画面
