import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// メモデータを取得するプロバイダー
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
              id: doc.id,
              content: data['content'] ?? '',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              isPublic: data['isPublic'] ?? false,
            );
          }).toList());
});

// メモの公開フラグを管理するStateProvider
final memoIsPublicProvider = StateProvider<bool>((ref) => false);

// メモデータのモデル
class MemoData {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isPublic;

  MemoData({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isPublic,
  });
}
