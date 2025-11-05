import 'package:cloud_firestore/cloud_firestore.dart';

/// 月次貢献度データ
/// Firestoreコレクション: monthly_contributions/{period}/{userId}
class MonthlyContributionData {
  final String userId;
  final String period; // "2025-10" 形式
  final int totalPoints; // 合計ポイント
  final int answerCount; // 回答数
  final int bestAnswerCount; // ベストアンサー数
  final List<String> answers; // 回答IDリスト
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyContributionData({
    required this.userId,
    required this.period,
    required this.totalPoints,
    required this.answerCount,
    required this.bestAnswerCount,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから変換
  factory MonthlyContributionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyContributionData(
      userId: data['user_id'] ?? '',
      period: data['period'] ?? '',
      totalPoints: data['total_points'] ?? 0,
      answerCount: data['answer_count'] ?? 0,
      bestAnswerCount: data['best_answer_count'] ?? 0,
      answers: List<String>.from(data['answers'] ?? []),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'period': period,
      'total_points': totalPoints,
      'answer_count': answerCount,
      'best_answer_count': bestAnswerCount,
      'answers': answers,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
