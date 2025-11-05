import 'package:cloud_firestore/cloud_firestore.dart';

/// 月次プールデータ
/// Firestoreコレクション: monthly_pools/{period}
class MonthlyPoolData {
  final String period; // "2025-10" 形式
  final int poolAmount; // プール総額（円）
  final int unlockCount; // アンロック数
  final bool distributed; // 分配済みフラグ
  final DateTime? distributedAt; // 分配日時
  final bool isTestPeriod; // テスト期間フラグ
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyPoolData({
    required this.period,
    required this.poolAmount,
    required this.unlockCount,
    required this.distributed,
    this.distributedAt,
    required this.isTestPeriod,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから変換
  factory MonthlyPoolData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyPoolData(
      period: data['period'] ?? '',
      poolAmount: data['pool_amount'] ?? 0,
      unlockCount: data['unlock_count'] ?? 0,
      distributed: data['distributed'] ?? false,
      distributedAt: data['distributed_at'] != null
          ? (data['distributed_at'] as Timestamp).toDate()
          : null,
      isTestPeriod: data['is_test_period'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'period': period,
      'pool_amount': poolAmount,
      'unlock_count': unlockCount,
      'distributed': distributed,
      'distributed_at': distributedAt != null ? Timestamp.fromDate(distributedAt!) : null,
      'is_test_period': isTestPeriod,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// 現在の期間を取得（"2025-10"形式）
  static String getCurrentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
