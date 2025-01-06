import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

// StateNotifierを使用してアドバイスの状態を管理
class AdviceNotifier extends StateNotifier<Map<String, String?>> {
  AdviceNotifier() : super({});

  // Firestoreからアドバイスを取得し、キャッシュを更新
  Future<void> fetchAdvice(String memoId, String cardId, String userId) async {
    if (state.containsKey(memoId)) {
      // 既にキャッシュがある場合はスキップ
      return;
    }

    final adviceCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .collection('memos')
        .doc(memoId)
        .collection('advices');

    final adviceSnapshot = await adviceCollection.orderBy('createdAt', descending: true).limit(1).get();

    if (adviceSnapshot.docs.isNotEmpty) {
      final content = adviceSnapshot.docs.first['content'] as String;
      state = {...state, memoId: content};
    } else {
      state = {...state, memoId: null}; // アドバイスがない場合
    }
  }

  // 手動でキャッシュを更新
  void updateAdvice(String memoId, String content) {
    state = {...state, memoId: content};
  }
}

// StateNotifierProviderを定義
final adviceNotifierProvider = StateNotifierProvider<AdviceNotifier, Map<String, String?>>((ref) {
  return AdviceNotifier();
});
