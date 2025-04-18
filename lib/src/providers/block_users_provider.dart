/* 個人の特定につながるので、フロントではなく、バックエンドでブロックユーザーを管理する。
現状使用していないはずだが問題がなければ、削除する
  
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

// Riverpodでブロック済みユーザーを管理するProvider
final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  // 認証状態の変更を監視
  final user = ref.watch(authStateProvider).maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );

  if (user == null) {
    // ユーザーが認証されていない場合は空のリストを返す
    return Stream.value([]);
  }

  // ブロック済みユーザーを取得する
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('blockedUsers') // サブコレクション
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});
*/
