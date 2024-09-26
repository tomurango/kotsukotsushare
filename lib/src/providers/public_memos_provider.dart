import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/public_memo_data.dart';

// 公開されているメモを取得するプロバイダ
final publicMemosProvider = StreamProvider<List<PublicMemoData>>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('memos')
      .where('isPublic', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return PublicMemoData(
              id: doc.id,
              content: data['content'] ?? '',
              isPublic: data['isPublic'] ?? false,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              type: data['type'] ?? '',
              feeling: data['feeling'] ?? '',
              truth: data['truth'] ?? '',
            );
          }).toList());
});
