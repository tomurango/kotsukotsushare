import 'package:cloud_firestore/cloud_firestore.dart';

/// 報酬引き出しリクエストデータ
/// Firestoreコレクション: reward_withdrawals/{withdrawalId}
class RewardWithdrawalData {
  final String id;
  final String userId; // 引き出しリクエストユーザー
  final int amount; // 引き出し額（円）
  final String? bankName; // 銀行名
  final String? bankBranch; // 支店名
  final String? accountType; // 口座種別（普通/当座）
  final String? accountNumber; // 口座番号
  final String? accountHolder; // 口座名義
  final WithdrawalStatus status; // 引き出しステータス
  final DateTime createdAt;
  final DateTime? processedAt; // 処理完了日時

  RewardWithdrawalData({
    required this.id,
    required this.userId,
    required this.amount,
    this.bankName,
    this.bankBranch,
    this.accountType,
    this.accountNumber,
    this.accountHolder,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  /// Firestoreドキュメントから変換
  factory RewardWithdrawalData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardWithdrawalData(
      id: data['id'],
      userId: data['user_id'],
      amount: data['amount'],
      bankName: data['bank_name'],
      bankBranch: data['bank_branch'],
      accountType: data['account_type'],
      accountNumber: data['account_number'],
      accountHolder: data['account_holder'],
      status: WithdrawalStatus.fromString(data['status']),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      processedAt: data['processed_at'] != null
          ? (data['processed_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'account_type': accountType,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'status': status.toString(),
      'created_at': Timestamp.fromDate(createdAt),
      'processed_at': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  /// ローカルDBマップに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'account_type': accountType,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'status': status.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'processed_at': processedAt?.millisecondsSinceEpoch,
    };
  }

  /// ローカルDBマップから変換
  factory RewardWithdrawalData.fromMap(Map<String, dynamic> map) {
    return RewardWithdrawalData(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount'],
      bankName: map['bank_name'],
      bankBranch: map['bank_branch'],
      accountType: map['account_type'],
      accountNumber: map['account_number'],
      accountHolder: map['account_holder'],
      status: WithdrawalStatus.fromString(map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      processedAt: map['processed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['processed_at'])
          : null,
    );
  }
}

// 引き出しステータス
enum WithdrawalStatus {
  pending,
  test, // テスト期間中（実際の振込なし）
  processing,
  completed,
  failed,
  cancelled;

  static WithdrawalStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return WithdrawalStatus.pending;
      case 'test':
        return WithdrawalStatus.test;
      case 'processing':
        return WithdrawalStatus.processing;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'failed':
        return WithdrawalStatus.failed;
      case 'cancelled':
        return WithdrawalStatus.cancelled;
      default:
        return WithdrawalStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'pending';
      case WithdrawalStatus.test:
        return 'test';
      case WithdrawalStatus.processing:
        return 'processing';
      case WithdrawalStatus.completed:
        return 'completed';
      case WithdrawalStatus.failed:
        return 'failed';
      case WithdrawalStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case WithdrawalStatus.pending:
        return '申請中';
      case WithdrawalStatus.test:
        return 'テスト（振込なし）';
      case WithdrawalStatus.processing:
        return '処理中';
      case WithdrawalStatus.completed:
        return '完了';
      case WithdrawalStatus.failed:
        return '失敗';
      case WithdrawalStatus.cancelled:
        return 'キャンセル';
    }
  }
}
