import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_database.dart';
import '../providers/auth_provider.dart';
import '../providers/local_data_provider.dart';
import '../models/memo_data.dart';

// 移行状態の管理
enum MigrationStatus {
  idle,
  migrating,
  completed,
  error,
}

class MigrationProgress {
  final MigrationStatus status;
  final int totalCards;
  final int migratedCards;
  final int totalMemos;
  final int migratedMemos;
  final String? errorMessage;

  MigrationProgress({
    required this.status,
    this.totalCards = 0,
    this.migratedCards = 0,
    this.totalMemos = 0,
    this.migratedMemos = 0,
    this.errorMessage,
  });

  double get progress {
    final total = totalCards + totalMemos;
    final migrated = migratedCards + migratedMemos;
    return total > 0 ? migrated / total : 0.0;
  }
}

// 移行プログレスプロバイダー
final migrationProgressProvider = StateProvider<MigrationProgress>((ref) {
  return MigrationProgress(status: MigrationStatus.idle);
});

// 移行サービスプロバイダー
final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService(ref);
});

class MigrationService {
  final Ref ref;

  MigrationService(this.ref);

  // Firestoreからローカルにデータを移行
  Future<void> migrateFromFirestore() async {
    try {
      print('🔄 [Migration] Starting migration...');
      // 移行開始
      ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
        status: MigrationStatus.migrating,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }
      print('🔄 [Migration] User: ${user.uid}');

      // 1. カードデータを取得
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      final totalCards = cardsSnapshot.docs.length;
      print('🔄 [Migration] Found $totalCards cards');
      int migratedCards = 0;
      int totalMemos = 0;
      int migratedMemos = 0;

      // カード数を事前にカウント
      for (var cardDoc in cardsSnapshot.docs) {
        final memosSnapshot = await cardDoc.reference
            .collection('memos')
            .get();
        totalMemos += memosSnapshot.docs.length;
      }

      // プログレス更新
      ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
        status: MigrationStatus.migrating,
        totalCards: totalCards,
        totalMemos: totalMemos,
      );

      // 2. 各カードを移行
      for (var cardDoc in cardsSnapshot.docs) {
        final cardData = cardDoc.data();
        print('🔄 [Migration] Migrating card: ${cardDoc.id}');
        print('   - title: ${cardData['title']}');

        final card = CardData(
          id: cardDoc.id,
          title: cardData['title'] ?? '',
          description: cardData['description'] ?? '',
          category: cardData['category'] ?? '',
        );

        // カードをローカルに保存（参照用に残す）
        await LocalDatabase.insertCard(card);
        migratedCards++;
        print('   ✅ Card saved to local DB (for reference)');

        // プログレス更新
        ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
          status: MigrationStatus.migrating,
          totalCards: totalCards,
          migratedCards: migratedCards,
          totalMemos: totalMemos,
          migratedMemos: migratedMemos,
        );

        // 3. 各カードのメモを移行
        final memosSnapshot = await cardDoc.reference
            .collection('memos')
            .get();

        print('🔄 [Migration] Found ${memosSnapshot.docs.length} memos for card ${cardDoc.id}');

        for (var memoDoc in memosSnapshot.docs) {
          final memoData = memoDoc.data();
          print('   🔄 Migrating memo: ${memoDoc.id}');
          print('      - content: ${memoData['content']}');

          // tagsフィールドの処理（Firestoreではリスト、ローカルでは文字列配列）
          final tagsData = memoData['tags'];
          List<String> tags = [];
          if (tagsData is List) {
            tags = List<String>.from(tagsData);
          }

          // カードタイトルをタグとして追加（マイメモ画面でタグ分類できるように）
          final cardTitle = cardData['title'] ?? '';
          if (cardTitle.isNotEmpty && !tags.contains(cardTitle)) {
            tags.add(cardTitle);
          }
          print('      - tags (with card title): $tags');

          // createdAtのnullチェック
          DateTime createdAt;
          if (memoData['createdAt'] != null) {
            createdAt = (memoData['createdAt'] as Timestamp).toDate();
          } else {
            // createdAtがnullの場合は現在時刻を使用
            createdAt = DateTime.now();
            print('      ⚠️  createdAt is null, using current time');
          }

          // 独立メモとして保存（マイメモ画面で表示されるように）
          final memo = MemoData(
            cardId: 'standalone',  // 独立メモとして保存
            id: memoDoc.id,
            content: memoData['content'] ?? '',
            createdAt: createdAt,
            type: memoData['type'] ?? '',
            feeling: memoData['feeling'] ?? '',
            truth: memoData['truth'] ?? '',
            tags: tags,
          );

          // メモをローカルに保存
          await LocalDatabase.insertMemo(memo);
          migratedMemos++;
          print('      ✅ Memo saved to local DB as standalone with card title tag');

          // プログレス更新
          ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
            status: MigrationStatus.migrating,
            totalCards: totalCards,
            migratedCards: migratedCards,
            totalMemos: totalMemos,
            migratedMemos: migratedMemos,
          );
        }
      }

      // 移行完了
      print('✅ [Migration] Migration completed!');
      print('   - Cards: $migratedCards/$totalCards');
      print('   - Memos: $migratedMemos/$totalMemos');

      ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
        status: MigrationStatus.completed,
        totalCards: totalCards,
        migratedCards: migratedCards,
        totalMemos: totalMemos,
        migratedMemos: migratedMemos,
      );

      // 移行完了フラグをマーク
      await ref.read(useLocalDataProvider.notifier).markMigrationCompleted();

    } catch (e) {
      // エラー処理
      print('❌ [Migration] Migration failed: $e');
      ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Firestoreのデータを削除（移行後のクリーンアップ）
  Future<void> deleteFirestoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }

    try {
      // カードとその下のメモを全て削除
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var cardDoc in cardsSnapshot.docs) {
        // メモを削除
        final memosSnapshot = await cardDoc.reference
            .collection('memos')
            .get();

        for (var memoDoc in memosSnapshot.docs) {
          batch.delete(memoDoc.reference);
        }

        // カードを削除
        batch.delete(cardDoc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Firestoreデータの削除に失敗しました: $e');
    }
  }

  // 移行データの検証
  Future<bool> validateMigration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Firestoreのデータ数を取得
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      int firestoreCards = cardsSnapshot.docs.length;
      int firestoreMemos = 0;

      for (var cardDoc in cardsSnapshot.docs) {
        final memosSnapshot = await cardDoc.reference
            .collection('memos')
            .get();
        firestoreMemos += memosSnapshot.docs.length;
      }

      // ローカルのデータ数を取得
      final localCounts = await LocalDatabase.getDataCounts();

      // データ数が一致するかチェック
      return localCounts['cards'] == firestoreCards &&
             localCounts['memos'] == firestoreMemos;

    } catch (e) {
      return false;
    }
  }

  // 移行状態をリセット
  void resetMigrationStatus() {
    ref.read(migrationProgressProvider.notifier).state = MigrationProgress(
      status: MigrationStatus.idle,
    );
  }
}