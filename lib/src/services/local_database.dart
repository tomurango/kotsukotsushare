import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memo_data.dart';
import '../models/question_payment_data.dart';
import '../models/answer_reward_data.dart';
import '../models/question_unlock_data.dart';
import '../providers/auth_provider.dart';

class LocalDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chokushii_local.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 回答開封テーブルを追加（旧バージョン互換性のため）
      await db.execute('''
        CREATE TABLE answer_unlocks (
          id TEXT PRIMARY KEY,
          answer_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          unlocked_by TEXT NOT NULL,
          amount INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_answer_unlocks_answer_id ON answer_unlocks(answer_id)');
      await db.execute('CREATE INDEX idx_answer_unlocks_unlocked_by ON answer_unlocks(unlocked_by)');
    }

    if (oldVersion < 3) {
      // 質問開封テーブルを追加（Option C: 貢献度プールモデル）
      await db.execute('''
        CREATE TABLE question_unlocks (
          id TEXT PRIMARY KEY,
          question_id TEXT NOT NULL,
          unlocked_by TEXT NOT NULL,
          amount INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_question_unlocks_question_id ON question_unlocks(question_id)');
      await db.execute('CREATE INDEX idx_question_unlocks_unlocked_by ON question_unlocks(unlocked_by)');

      // 古い answer_unlocks テーブルがあれば削除
      await db.execute('DROP TABLE IF EXISTS answer_unlocks');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    // カードテーブル
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // メモテーブル
    await db.execute('''
      CREATE TABLE memos (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        type TEXT NOT NULL,
        feeling TEXT NOT NULL,
        truth TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');

    // 質問課金テーブル
    await db.execute('''
      CREATE TABLE question_payments (
        id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        payment_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // 回答報酬テーブル
    await db.execute('''
      CREATE TABLE answer_rewards (
        id TEXT PRIMARY KEY,
        answer_id TEXT NOT NULL,
        answerer_id TEXT NOT NULL,
        question_payment_id TEXT NOT NULL,
        reward_amount INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        paid_at INTEGER
      )
    ''');

    // 報酬引き出し履歴テーブル
    await db.execute('''
      CREATE TABLE reward_withdrawals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        status TEXT NOT NULL,
        requested_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

    // 質問開封テーブル (v3以降: 貢献度プールモデル)
    await db.execute('''
      CREATE TABLE question_unlocks (
        id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL,
        unlocked_by TEXT NOT NULL,
        amount INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_memos_card_id ON memos(card_id)');
    await db.execute('CREATE INDEX idx_memos_created_at ON memos(created_at)');
    await db.execute('CREATE INDEX idx_question_payments_user_id ON question_payments(user_id)');
    await db.execute('CREATE INDEX idx_answer_rewards_answerer_id ON answer_rewards(answerer_id)');
    await db.execute('CREATE INDEX idx_reward_withdrawals_user_id ON reward_withdrawals(user_id)');
    await db.execute('CREATE INDEX idx_question_unlocks_question_id ON question_unlocks(question_id)');
    await db.execute('CREATE INDEX idx_question_unlocks_unlocked_by ON question_unlocks(unlocked_by)');
  }

  // カード操作
  static Future<void> insertCard(CardData card) async {
    final db = await database;
    await db.insert(
      'cards',
      {
        'id': card.id,
        'title': card.title,
        'description': card.description,
        'category': card.category,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<CardData>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cards');

    return List.generate(maps.length, (i) {
      return CardData(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        category: maps[i]['category'],
      );
    });
  }

  static Future<void> updateCard(CardData card) async {
    final db = await database;
    await db.update(
      'cards',
      {
        'title': card.title,
        'description': card.description,
        'category': card.category,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  static Future<void> deleteCard(String cardId) async {
    final db = await database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  // メモ操作
  static Future<void> insertMemo(MemoData memo) async {
    final db = await database;
    await db.insert(
      'memos',
      {
        'id': memo.id,
        'card_id': memo.cardId,
        'content': memo.content,
        'created_at': memo.createdAt.millisecondsSinceEpoch,
        'type': memo.type,
        'feeling': memo.feeling,
        'truth': memo.truth,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<MemoData>> getMemosByCardId(String cardId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memos',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MemoData(
        cardId: maps[i]['card_id'],
        id: maps[i]['id'],
        content: maps[i]['content'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
        type: maps[i]['type'],
        feeling: maps[i]['feeling'],
        truth: maps[i]['truth'],
      );
    });
  }

  static Future<void> updateMemo(MemoData memo) async {
    final db = await database;
    await db.update(
      'memos',
      {
        'content': memo.content,
        'type': memo.type,
        'feeling': memo.feeling,
        'truth': memo.truth,
      },
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  static Future<void> deleteMemo(String memoId) async {
    final db = await database;
    await db.delete(
      'memos',
      where: 'id = ?',
      whereArgs: [memoId],
    );
  }

  // データベース初期化
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('memos');
    await db.delete('cards');
  }

  // 質問課金操作
  static Future<void> insertQuestionPayment(QuestionPaymentData payment) async {
    final db = await database;
    await db.insert(
      'question_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<QuestionPaymentData>> getQuestionPaymentsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'question_payments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return QuestionPaymentData.fromMap(maps[i]);
    });
  }

  static Future<QuestionPaymentData?> getQuestionPayment(String questionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'question_payments',
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return QuestionPaymentData.fromMap(maps.first);
    }
    return null;
  }

  // 回答報酬操作
  static Future<void> insertAnswerReward(AnswerRewardData reward) async {
    final db = await database;
    await db.insert(
      'answer_rewards',
      reward.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<AnswerRewardData>> getAnswerRewardsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'answer_rewards',
      where: 'answerer_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return AnswerRewardData.fromMap(maps[i]);
    });
  }

  static Future<void> updateAnswerRewardStatus(String rewardId, RewardStatus status, {DateTime? paidAt}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'status': status.toString(),
    };

    if (paidAt != null) {
      updateData['paid_at'] = paidAt.millisecondsSinceEpoch;
    }

    await db.update(
      'answer_rewards',
      updateData,
      where: 'id = ?',
      whereArgs: [rewardId],
    );
  }

  // 報酬統計
  static Future<int> getTotalEarnings(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(reward_amount) as total FROM answer_rewards WHERE answerer_id = ? AND status = ?',
      [userId, RewardStatus.paid.toString()],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  static Future<int> getPendingEarnings(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(reward_amount) as total FROM answer_rewards WHERE answerer_id = ? AND status = ?',
      [userId, RewardStatus.pending.toString()],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  // データ件数確認
  static Future<Map<String, int>> getDataCounts() async {
    final db = await database;
    final cardCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards')
    ) ?? 0;
    final memoCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM memos')
    ) ?? 0;

    return {
      'cards': cardCount,
      'memos': memoCount,
    };
  }

  // 質問開封操作（貢献度プールモデル）
  static Future<void> insertQuestionUnlock(QuestionUnlockData unlock) async {
    final db = await database;
    await db.insert(
      'question_unlocks',
      unlock.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<QuestionUnlockData>> getQuestionUnlocksByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'question_unlocks',
      where: 'unlocked_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return QuestionUnlockData.fromMap(maps[i]);
    });
  }

  static Future<bool> isQuestionUnlockedBy(String questionId, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'question_unlocks',
      where: 'question_id = ? AND unlocked_by = ?',
      whereArgs: [questionId, userId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // 質問開封の統計
  static Future<int> getTotalUnlockCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM question_unlocks WHERE unlocked_by = ?',
      [userId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalUnlockSpent(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM question_unlocks WHERE unlocked_by = ?',
      [userId],
    );

    return (result.first['total'] as int?) ?? 0;
  }
}