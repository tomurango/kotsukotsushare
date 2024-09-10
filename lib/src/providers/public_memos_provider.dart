import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MemoDataモデル
class MemoData {
  final String id;
  final String content;
  final bool isPublic;

  MemoData({
    required this.id,
    required this.content,
    required this.isPublic,
  });
}

// メモを取得するプロバイダ
final publicMemosProvider = StreamProvider<List<MemoData>>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('memos')
      .where('isPublic', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return MemoData(
              id: doc.id,
              content: data['content'] ?? '',
              isPublic: data['isPublic'] ?? false,
            );
          }).toList());
});
