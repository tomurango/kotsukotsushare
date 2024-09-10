import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Reflectionデータを取得するプロバイダー
final reflectionsProvider = StreamProvider.family<List<ReflectionData>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('reflections')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ReflectionData(
              id: doc.id,
              memoContent: data['memoContent'] ?? '',
              reflection: data['reflection'] ?? '',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
            );
          }).toList());
});

// Reflectionデータのモデル
class ReflectionData {
  final String id;
  final String memoContent;
  final String reflection;
  final DateTime createdAt;

  ReflectionData({
    required this.id,
    required this.memoContent,
    required this.reflection,
    required this.createdAt,
  });
}
