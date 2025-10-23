// 回答報酬データのモデル
class AnswerRewardData {
  final String id;
  final String answerId;
  final String answererId;
  final String questionPaymentId;
  final int rewardAmount;
  final RewardStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;

  AnswerRewardData({
    required this.id,
    required this.answerId,
    required this.answererId,
    required this.questionPaymentId,
    required this.rewardAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory AnswerRewardData.fromMap(Map<String, dynamic> map) {
    return AnswerRewardData(
      id: map['id'],
      answerId: map['answer_id'],
      answererId: map['answerer_id'],
      questionPaymentId: map['question_payment_id'],
      rewardAmount: map['reward_amount'],
      status: RewardStatus.fromString(map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      paidAt: map['paid_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paid_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'answer_id': answerId,
      'answerer_id': answererId,
      'question_payment_id': questionPaymentId,
      'reward_amount': rewardAmount,
      'status': status.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'paid_at': paidAt?.millisecondsSinceEpoch,
    };
  }
}

// 報酬ステータス
enum RewardStatus {
  pending,
  paid,
  cancelled;

  static RewardStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RewardStatus.pending;
      case 'paid':
        return RewardStatus.paid;
      case 'cancelled':
        return RewardStatus.cancelled;
      default:
        return RewardStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case RewardStatus.pending:
        return 'pending';
      case RewardStatus.paid:
        return 'paid';
      case RewardStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case RewardStatus.pending:
        return '支払い待ち';
      case RewardStatus.paid:
        return '支払い済み';
      case RewardStatus.cancelled:
        return 'キャンセル';
    }
  }
}