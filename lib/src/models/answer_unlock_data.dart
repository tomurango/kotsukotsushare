// 回答開封データのモデル
class AnswerUnlockData {
  final String id;
  final String answerId;
  final String questionId;
  final String unlockedBy; // 開封したユーザーID
  final int amount; // 支払った金額（100円）
  final DateTime createdAt;

  AnswerUnlockData({
    required this.id,
    required this.answerId,
    required this.questionId,
    required this.unlockedBy,
    required this.amount,
    required this.createdAt,
  });

  factory AnswerUnlockData.fromMap(Map<String, dynamic> map) {
    return AnswerUnlockData(
      id: map['id'],
      answerId: map['answer_id'],
      questionId: map['question_id'],
      unlockedBy: map['unlocked_by'],
      amount: map['amount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'answer_id': answerId,
      'question_id': questionId,
      'unlocked_by': unlockedBy,
      'amount': amount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
