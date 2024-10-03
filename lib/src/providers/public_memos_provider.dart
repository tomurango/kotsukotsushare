import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'block_users_provider.dart';
import 'auth_provider.dart';
import '../models/public_memo_data.dart';

final publicMemosProvider = StreamProvider<List<PublicMemoData>>((ref) async* {
  // 認証状態の変更を監視
  final user = ref.watch(authStateProvider).maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );

  // ユーザーがいない場合、空のリストを返す
  if (user == null) {
    yield [];
    return;
  }

  // 自分のUIDを取得
  final userId = user.uid;

  // ブロック済みユーザーのUIDをProviderから取得
  final blockedUserIds = ref.watch(blockedUsersProvider).maybeWhen(
    data: (blockedUsers) => blockedUsers,
    orElse: () => [],
  );

  // 自分とブロックユーザー以外の公開メモを取得
  yield* FirebaseFirestore.instance
      .collectionGroup('memos')
      .where('isPublic', isEqualTo: true)
      .where('userId', isNotEqualTo: userId) // 自分のメモを除外
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final memoUserId = data['userId'] ?? '';

              // ブロック済みユーザーのメモを除外
              return !blockedUserIds.contains(memoUserId);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return PublicMemoData(
                id: doc.id,
                content: data['content'] ?? '',
                isPublic: data['isPublic'] ?? false,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                type: data['type'] ?? '',
                feeling: data['feeling'] ?? '',
                truth: data['truth'] ?? '',
                userId: data['userId'] ?? '',
              );
            }).toList();
      })
      .handleError((error) {
        // エラーハンドリングのログ
        print('Error in Firestore query: $error');
      });
});
