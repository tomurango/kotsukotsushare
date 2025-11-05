import 'package:cloud_firestore/cloud_firestore.dart';

// 質問開封データのモデル
class QuestionUnlockData {
  final String id;
  final String questionId;
  final String unlockedBy; // 開封したユーザーID
  final int amount; // 支払った金額（160円、テスト期間中は無料）
  final bool isTest; // テストフラグ（テスト期間中はtrue）
  final DateTime createdAt;

  QuestionUnlockData({
    required this.id,
    required this.questionId,
    required this.unlockedBy,
    required this.amount,
    required this.isTest,
    required this.createdAt,
  });

  factory QuestionUnlockData.fromMap(Map<String, dynamic> map) {
    return QuestionUnlockData(
      id: map['id'],
      questionId: map['question_id'],
      unlockedBy: map['unlocked_by'],
      amount: map['amount'],
      isTest: map['is_test'] ?? true, // デフォルトはテスト
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  factory QuestionUnlockData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionUnlockData(
      id: data['id'],
      questionId: data['question_id'],
      unlockedBy: data['unlocked_by'],
      amount: data['amount'],
      isTest: data['is_test'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'unlocked_by': unlockedBy,
      'amount': amount,
      'is_test': isTest,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'question_id': questionId,
      'unlocked_by': unlockedBy,
      'amount': amount,
      'is_test': isTest,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
