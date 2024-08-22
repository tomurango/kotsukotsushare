import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 認証状態を管理するプロバイダ
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});


final userProvider = Provider<String?>((ref) {
  // 仮のユーザー名。実際には、認証状態から取得します。
  // nullの場合、ログインしていないとみなします。
  return "ユーザー名"; // ここを実際のユーザ名を取得する処理に置き換えます
});

// ユーザー情報を管理するプロバイダ（例として）
/*
final userProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).data?.value;
  return user?.displayName;
});*/
