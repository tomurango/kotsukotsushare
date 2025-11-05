import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memo_data.dart';

// メモ表示モード（時系列 or タグ分類）
enum MemoViewMode {
  chronological, // 時系列表示（デフォルト）
  tags, // タグ分類表示
}

// メモ表示モードのプロバイダー（カードごと）
final memoViewModeProvider = StateProvider.family<MemoViewMode, String>((ref, cardId) {
  return MemoViewMode.chronological; // デフォルトは時系列
});

// 独立メモ（カードなし）の表示モード
final standaloneMemoViewModeProvider = StateProvider<MemoViewMode>((ref) {
  return MemoViewMode.chronological;
});

// 独立メモ用の定数
const String STANDALONE_CARD_ID = 'standalone';

// メモデータを取得するプロバイダ
final memosProvider = StreamProvider.family<List<MemoData>, String>((ref, cardId) {
  final user = FirebaseAuth.instance.currentUser;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('cards')
      .doc(cardId)
      .collection('memos')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return MemoData(
              cardId: cardId,
              id: doc.id,
              content: data['content'] ?? '',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              //isPublic: data['isPublic'] ?? false,
              type: data['type'] ?? '',
              feeling: data['feeling'] ?? '',
              truth: data['truth'] ?? '',
              tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
            );
          }).toList());
});
