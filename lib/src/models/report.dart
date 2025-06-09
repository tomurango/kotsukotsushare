class MonthlyReport {
  final String month;
  final int entryCount;
  final double averageMoodScore;
  final String previousMonthDiff;
  final List<String> commonBiases;
  final List<MoodTrend> moodTrends;
  final List<BiasStat> biasStats;
  final Insight insight;

  MonthlyReport({
    required this.month,
    required this.entryCount,
    required this.averageMoodScore,
    required this.previousMonthDiff,
    required this.commonBiases,
    required this.moodTrends,
    required this.biasStats,
    required this.insight,
  });

  // ダミーデータ：2025年4月
  factory MonthlyReport.mockApril() => MonthlyReport(
        month: '2025年4月',
        entryCount: 24,
        averageMoodScore: 1.2,
        previousMonthDiff: '-0.8',
        commonBiases: ['白黒思考', '心の読みすぎ'],
        moodTrends: [
          MoodTrend(day: 1, score: 2),
          MoodTrend(day: 2, score: 5),
          MoodTrend(day: 3, score: -3),
          MoodTrend(day: 4, score: 1),
          MoodTrend(day: 5, score: 4),
        ],
        biasStats: [
          BiasStat(bias: '白黒思考', count: 8, avgScore: -3.5),
          BiasStat(bias: '心の読みすぎ', count: 5, avgScore: -2.8),
        ],
        insight: Insight(
          bias: '白黒思考',
          count: 8,
          avgScore: -3.5,
          example: 'またゲームしてしまった。やっぱり自分はダメだ',
          comment: 'このような思考パターンは、「小さな失敗」を「全否定」に繋げやすくなります。',
          question: '“ダメ”じゃない部分も、ほんとはどこかにありませんか？',
        ),
      );

  // 他の月のモックも必要に応じて追加
  factory MonthlyReport.mockMarch() => MonthlyReport.mockApril().copyWith(month: '2025年3月');
  factory MonthlyReport.mockFebruary() => MonthlyReport.mockApril().copyWith(month: '2025年2月');

  MonthlyReport copyWith({
    String? month,
    int? entryCount,
    double? averageMoodScore,
    String? previousMonthDiff,
    List<String>? commonBiases,
    List<MoodTrend>? moodTrends,
    List<BiasStat>? biasStats,
    Insight? insight,
  }) {
    return MonthlyReport(
      month: month ?? this.month,
      entryCount: entryCount ?? this.entryCount,
      averageMoodScore: averageMoodScore ?? this.averageMoodScore,
      previousMonthDiff: previousMonthDiff ?? this.previousMonthDiff,
      commonBiases: commonBiases ?? this.commonBiases,
      moodTrends: moodTrends ?? this.moodTrends,
      biasStats: biasStats ?? this.biasStats,
      insight: insight ?? this.insight,
    );
  }
}

class MoodTrend {
  final int day;
  final double score;

  MoodTrend({required this.day, required this.score});
}

class BiasStat {
  final String bias;
  final int count;
  final double avgScore;

  BiasStat({required this.bias, required this.count, required this.avgScore});
}

class Insight {
  final String bias;
  final int count;
  final double avgScore;
  final String example;
  final String comment;
  final String question;

  Insight({
    required this.bias,
    required this.count,
    required this.avgScore,
    required this.example,
    required this.comment,
    required this.question,
  });
}
