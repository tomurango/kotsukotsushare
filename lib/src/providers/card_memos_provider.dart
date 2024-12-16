import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memo_data.dart';

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
              isPublic: data['isPublic'] ?? false,
              type: data['type'] ?? '',
              feeling: data['feeling'] ?? '',
              truth: data['truth'] ?? '',
            );
          }).toList());
});

// 公開フラグを管理するためのStateProvider
final isPublicProvider = StateProvider<bool>((ref) {
  return true; // デフォルトで公開状態に設定
});
