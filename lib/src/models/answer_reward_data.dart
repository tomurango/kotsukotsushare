import 'package:cloud_firestore/cloud_firestore.dart';

/// 回答報酬データのモデル（月次プール方式）
/// Firestoreコレクション: answer_rewards/{rewardId}
class AnswerRewardData {
  final String id;
  final String period; // "2025-10" 形式
  final String userId; // 報酬受取者のユーザーID
  final int rewardAmount; // 報酬額（円）
  final int contributionPoints; // 貢献度ポイント
  final bool isBestAnswerer; // ベストアンサーを獲得したか
  final RewardStatus status; // 報酬ステータス
  final DateTime createdAt;
  final DateTime? paidAt;

  AnswerRewardData({
    required this.id,
    required this.period,
    required this.userId,
    required this.rewardAmount,
    required this.contributionPoints,
    required this.isBestAnswerer,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  /// Firestoreドキュメントから変換
  factory AnswerRewardData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnswerRewardData(
      id: data['id'],
      period: data['period'],
      userId: data['user_id'],
      rewardAmount: data['reward_amount'],
      contributionPoints: data['contribution_points'] ?? 0,
      isBestAnswerer: data['is_best_answerer'] ?? false,
      status: RewardStatus.fromString(data['status']),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      paidAt: data['paid_at'] != null
          ? (data['paid_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'period': period,
      'user_id': userId,
      'reward_amount': rewardAmount,
      'contribution_points': contributionPoints,
      'is_best_answerer': isBestAnswerer,
      'status': status.toString(),
      'created_at': Timestamp.fromDate(createdAt),
      'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  /// ローカルDBマップに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'user_id': userId,
      'reward_amount': rewardAmount,
      'contribution_points': contributionPoints,
      'is_best_answerer': isBestAnswerer ? 1 : 0,
      'status': status.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'paid_at': paidAt?.millisecondsSinceEpoch,
    };
  }

  /// ローカルDBマップから変換
  factory AnswerRewardData.fromMap(Map<String, dynamic> map) {
    return AnswerRewardData(
      id: map['id'],
      period: map['period'],
      userId: map['user_id'],
      rewardAmount: map['reward_amount'],
      contributionPoints: map['contribution_points'] ?? 0,
      isBestAnswerer: (map['is_best_answerer'] ?? 0) == 1,
      status: RewardStatus.fromString(map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      paidAt: map['paid_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paid_at'])
          : null,
    );
  }
}

// 報酬ステータス
enum RewardStatus {
  pending,
  test, // テスト期間中（実際の支払いなし）
  paid,
  cancelled;

  static RewardStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RewardStatus.pending;
      case 'test':
        return RewardStatus.test;
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
      case RewardStatus.test:
        return 'test';
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
      case RewardStatus.test:
        return 'テスト（支払いなし）';
      case RewardStatus.paid:
        return '支払い済み';
      case RewardStatus.cancelled:
        return 'キャンセル';
    }
  }
}
