import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_provider.dart';

final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return null; // ユーザーがログインしていない場合
  }

  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();

  if (docSnapshot.exists) {
    return docSnapshot.data();
  } else {
    // 初期データをFirestoreに作成
    await userDoc.set({'tutorialCompleted': false});
    return {'tutorialCompleted': false};
  }
});
