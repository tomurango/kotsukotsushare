// 質問開封データのモデル
class QuestionUnlockData {
  final String id;
  final String questionId;
  final String unlockedBy; // 開封したユーザーID
  final int amount; // 支払った金額（100円）
  final DateTime createdAt;

  QuestionUnlockData({
    required this.id,
    required this.questionId,
    required this.unlockedBy,
    required this.amount,
    required this.createdAt,
  });

  factory QuestionUnlockData.fromMap(Map<String, dynamic> map) {
    return QuestionUnlockData(
      id: map['id'],
      questionId: map['question_id'],
      unlockedBy: map['unlocked_by'],
      amount: map['amount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'unlocked_by': unlockedBy,
      'amount': amount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
