// 質問課金データのモデル
class QuestionPaymentData {
  final String id;
  final String questionId;
  final String userId;
  final int amount;
  final PaymentType paymentType;
  final DateTime createdAt;

  QuestionPaymentData({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.amount,
    required this.paymentType,
    required this.createdAt,
  });

  factory QuestionPaymentData.fromMap(Map<String, dynamic> map) {
    return QuestionPaymentData(
      id: map['id'],
      questionId: map['question_id'],
      userId: map['user_id'],
      amount: map['amount'],
      paymentType: PaymentType.fromString(map['payment_type']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'user_id': userId,
      'amount': amount,
      'payment_type': paymentType.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

// 課金タイプ
enum PaymentType {
  basic,
  priority,
  urgent;

  static PaymentType fromString(String value) {
    switch (value) {
      case 'basic':
        return PaymentType.basic;
      case 'priority':
        return PaymentType.priority;
      case 'urgent':
        return PaymentType.urgent;
      default:
        return PaymentType.basic;
    }
  }

  @override
  String toString() {
    switch (this) {
      case PaymentType.basic:
        return 'basic';
      case PaymentType.priority:
        return 'priority';
      case PaymentType.urgent:
        return 'urgent';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentType.basic:
        return '基本質問';
      case PaymentType.priority:
        return '優先質問';
      case PaymentType.urgent:
        return '緊急質問';
    }
  }

  int get amount {
    switch (this) {
      case PaymentType.basic:
        return 100;
      case PaymentType.priority:
        return 300;
      case PaymentType.urgent:
        return 500;
    }
  }

  String get description {
    switch (this) {
      case PaymentType.basic:
        return '通常の質問投稿';
      case PaymentType.priority:
        return '上位表示される質問';
      case PaymentType.urgent:
        return '即レスが期待される緊急質問';
    }
  }
}