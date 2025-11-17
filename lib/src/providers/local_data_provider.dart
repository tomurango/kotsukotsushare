import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_database.dart';
import '../services/migration_service.dart';
import '../providers/auth_provider.dart';
import '../providers/card_memos_provider.dart';
import '../models/memo_data.dart';

// SharedPreferencesプロバイダー
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ローカルデータの使用状態を管理（永続化対応）
final useLocalDataProvider = StateNotifierProvider<UseLocalDataNotifier, bool>((ref) {
  return UseLocalDataNotifier(ref);
});

class UseLocalDataNotifier extends StateNotifier<bool> {
  final Ref ref;
  bool _initialized = false;
  bool _migrationCompleted = false;

  UseLocalDataNotifier(this.ref) : super(false) {
    _initialize();
  }

  bool get migrationCompleted => _migrationCompleted;

  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      print('🔍 [LocalDataProvider] Initializing...');
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print('🔍 [LocalDataProvider] User authenticated: ${user.uid}');
        final key = 'use_local_data_${user.uid}';
        final migrationKey = 'migration_completed_${user.uid}';
        final autoMigrationKey = 'auto_migration_done_${user.uid}';

        // 移行完了フラグをチェック
        _migrationCompleted = prefs.getBool(migrationKey) ?? false;
        final autoMigrationDone = prefs.getBool(autoMigrationKey) ?? false;

        print('🔍 [LocalDataProvider] Migration status:');
        print('   - migrationCompleted: $_migrationCompleted');
        print('   - autoMigrationDone: $autoMigrationDone');

        // すべてのユーザーでローカル使用（原則ローカル）
        state = true;
        await prefs.setBool(key, true);
        print('🔍 [LocalDataProvider] Set to use local data');

        // 自動移行がまだ行われていない場合のみチェック
        if (!autoMigrationDone && !_migrationCompleted) {
          print('🔍 [LocalDataProvider] Checking for Firestore data...');
          final hasFirestoreData = await _checkFirestoreData();
          print('🔍 [LocalDataProvider] Has Firestore data: $hasFirestoreData');

          if (hasFirestoreData) {
            // Firestoreにデータがある → 自動的にローカルに移行
            print('🔍 [LocalDataProvider] Starting auto-migration...');
            await _performAutoMigration();
            await prefs.setBool(autoMigrationKey, true);
            print('🔍 [LocalDataProvider] Auto-migration completed');
          } else {
            // データがない → 自動移行不要フラグを立てる
            print('🔍 [LocalDataProvider] No data to migrate, marking as done');
            await prefs.setBool(autoMigrationKey, true);
          }
        } else {
          print('🔍 [LocalDataProvider] Skipping auto-migration (already done or completed)');
        }
      } else {
        print('🔍 [LocalDataProvider] No user authenticated');
      }

      _initialized = true;
      print('🔍 [LocalDataProvider] Initialization complete');
    } catch (e) {
      // エラーの場合もローカル使用
      print('❌ [LocalDataProvider] Initialization error: $e');
      state = true;
      _initialized = true;
    }
  }

  // 自動移行を実行（透過的にバックグラウンドで）
  Future<void> _performAutoMigration() async {
    try {
      print('🔄 Auto-migrating Firestore data to local...');
      final migrationService = ref.read(migrationServiceProvider);
      await migrationService.migrateFromFirestore();
      print('✅ Auto-migration completed successfully');
    } catch (e) {
      print('❌ Auto-migration failed: $e');
      // エラーが発生してもローカル使用は継続
      // ユーザーは手動でデータ管理画面から移行可能
    }
  }

  Future<bool> _checkFirestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔍 [_checkFirestoreData] No user authenticated');
        return false;
      }

      print('🔍 [_checkFirestoreData] Checking path: users/${user.uid}/cards');
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .limit(1)
          .get();

      print('🔍 [_checkFirestoreData] Found ${cardsSnapshot.docs.length} cards');
      if (cardsSnapshot.docs.isNotEmpty) {
        print('🔍 [_checkFirestoreData] First card ID: ${cardsSnapshot.docs.first.id}');
      }

      return cardsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ [_checkFirestoreData] Error: $e');
      return false;
    }
  }

  Future<void> setUseLocal(bool useLocal) async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final key = 'use_local_data_${user.uid}';

        // 移行完了後はクラウドに戻せない制限をチェック
        if (_migrationCompleted && !useLocal) {
          throw Exception('移行完了後はクラウドデータに戻すことはできません');
        }

        await prefs.setBool(key, useLocal);
        state = useLocal;
      }
    } catch (e) {
      if (!_migrationCompleted) {
        state = useLocal;
      }
      rethrow;
    }
  }

  // 移行完了をマーク
  Future<void> markMigrationCompleted() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final migrationKey = 'migration_completed_${user.uid}';
        await prefs.setBool(migrationKey, true);
        _migrationCompleted = true;
      }
    } catch (e) {
      // エラーは無視（移行完了フラグの設定失敗は致命的でない）
    }
  }

  // 初期化完了を待つ
  Future<void> waitForInitialization() async {
    while (!_initialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
}

// ローカルカードデータプロバイダー
final localCardsProvider = StreamProvider.autoDispose<List<CardData>>((ref) {
  // useLocalDataProviderの状態を監視
  final useLocal = ref.watch(useLocalDataProvider);

  if (!useLocal) {
    // ローカルデータを使用しない場合は空のリストを返す
    return Stream.value([]);
  }

  // ローカルデータベースからカードを取得
  return Stream.periodic(const Duration(milliseconds: 500), (_) async {
    return await LocalDatabase.getAllCards();
  }).asyncMap((future) => future);
});

// ローカルメモデータプロバイダー
final localMemosProvider = StreamProvider.family<List<MemoData>, String>((ref, cardId) {
  final useLocal = ref.watch(useLocalDataProvider);

  if (!useLocal) {
    return Stream.value([]);
  }

  return Stream.periodic(const Duration(milliseconds: 500), (_) async {
    return await LocalDatabase.getMemosByCardId(cardId);
  }).asyncMap((future) => future);
});

// ローカル独立メモデータプロバイダー
final localStandaloneMemosProvider = StreamProvider<List<MemoData>>((ref) {
  final useLocal = ref.watch(useLocalDataProvider);

  if (!useLocal) {
    return Stream.value([]);
  }

  return Stream.periodic(const Duration(milliseconds: 500), (_) async {
    return await LocalDatabase.getStandaloneMemos();
  }).asyncMap((future) => future);
});

// 統合カードデータプロバイダー（FirestoreとLocalを切り替え）
final unifiedCardsProvider = StreamProvider.autoDispose<List<CardData>>((ref) async* {
  final useLocal = ref.watch(useLocalDataProvider);

  if (useLocal) {
    await for (final cards in ref.watch(localCardsProvider.stream)) {
      yield cards;
    }
  } else {
    await for (final cards in ref.watch(cardsProvider.stream)) {
      yield cards;
    }
  }
});

// 統合メモデータプロバイダー（FirestoreとLocalを切り替え）
final unifiedMemosProvider = StreamProvider.family<List<MemoData>, String>((ref, cardId) async* {
  final useLocal = ref.watch(useLocalDataProvider);

  if (useLocal) {
    await for (final memos in ref.watch(localMemosProvider(cardId).stream)) {
      yield memos;
    }
  } else {
    await for (final memos in ref.watch(memosProvider(cardId).stream)) {
      yield memos;
    }
  }
});

// 統合独立メモデータプロバイダー（FirestoreとLocalを切り替え）
final unifiedStandaloneMemosProvider = StreamProvider<List<MemoData>>((ref) async* {
  final useLocal = ref.watch(useLocalDataProvider);

  if (useLocal) {
    await for (final memos in ref.watch(localStandaloneMemosProvider.stream)) {
      yield memos;
    }
  } else {
    // Firestoreからも独立メモを取得（互換性）
    await for (final memos in ref.watch(memosProvider('standalone').stream)) {
      yield memos;
    }
  }
});

// ローカルデータ管理サービスプロバイダー
final localDataServiceProvider = Provider<LocalDataService>((ref) {
  return LocalDataService(ref);
});

class LocalDataService {
  final Ref ref;

  LocalDataService(this.ref);

  // ローカルデータの有効/無効を切り替え
  Future<void> toggleLocalData(bool useLocal) async {
    try {
      await ref.read(useLocalDataProvider.notifier).setUseLocal(useLocal);
    } catch (e) {
      rethrow; // エラーを再スロー
    }
  }

  // 移行完了状態を取得
  bool get isMigrationCompleted {
    return ref.read(useLocalDataProvider.notifier).migrationCompleted;
  }

  // カード操作
  Future<void> addCard(CardData card) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.insertCard(card);
    }
    // Firebase操作は既存のロジックを使用
  }

  Future<void> updateCard(CardData card) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.updateCard(card);
    }
    // Firebase操作は既存のロジックを使用
  }

  Future<void> deleteCard(String cardId) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.deleteCard(cardId);
    }
    // Firebase操作は既存のロジックを使用
  }

  // メモ操作
  Future<void> addMemo(MemoData memo) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.insertMemo(memo);
    }
    // Firebase操作は既存のロジックを使用
  }

  Future<void> updateMemo(MemoData memo) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.updateMemo(memo);
    }
    // Firebase操作は既存のロジックを使用
  }

  Future<void> deleteMemo(String memoId) async {
    final useLocal = ref.read(useLocalDataProvider);
    if (useLocal) {
      await LocalDatabase.deleteMemo(memoId);
    }
    // Firebase操作は既存のロジックを使用
  }

  // ローカルデータ統計
  Future<Map<String, int>> getLocalDataCounts() async {
    return await LocalDatabase.getDataCounts();
  }

  // ローカルデータクリア
  Future<void> clearLocalData() async {
    await LocalDatabase.clearAllData();
  }
}