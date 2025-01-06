import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 認証状態を管理するプロバイダ
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = Provider<User?>((ref) {
  // Firebaseの認証状態を監視し、現在のユーザーを返します
  return ref.watch(authStateProvider).value;
});

// 課金状態のProvider
final subscriptionStatusProvider = Provider<bool>((ref) {
  // 実際にはRevenueCatやFirestoreから状態を取得する
  return true; // 課金済みならtrue
});

// 現在のカードIDを管理するProvider
final currentCardIdProvider = StateProvider<String?>((ref) => null);

// Firestoreのカードデータを取得するProvider
final cardsProvider = StreamProvider.autoDispose<List<CardData>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) {
    return Stream.value([]);
  }

  final cardsStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cards')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return CardData(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              category: data['category'] ?? '',
            );
          }).toList());

  return cardsStream;
});

// カードデータのモデル
class CardData {
  final String id;
  final String title;
  final String description;
  final String category;

  CardData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });
}
