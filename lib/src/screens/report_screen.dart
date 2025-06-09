import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/report_provider.dart';

class ReportScreen extends ConsumerWidget {
  final void Function(int)? onNavigate;

  const ReportScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final report = ref.watch(reportProvider);

    final safeSelectedMonth = availableMonths.contains(selectedMonth)
        ? selectedMonth
        : availableMonths.first;

    return Stack(
      children: [
        // 🔽 背景：今のUI
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("月次レポート", style: Theme.of(context).textTheme.headlineSmall),
                    //const SizedBox(width: 16),
                    const Spacer(), // 左に寄せるための空きスペース
                    DropdownButton<String>(
                      value: safeSelectedMonth,
                      items: availableMonths.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text('$month月'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(selectedMonthProvider.notifier).state = value;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('📊 今月のまとめ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('記録数：${report.entryCount}件'),
                Text('平均気分スコア：${report.averageMoodScore}（先月比 ${report.previousMonthDiff}）'),
                Text('よく見られた思い込み：${report.commonBiases.join('、')}'),
                const SizedBox(height: 24),

                Text('📉 気分スコアの推移', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: report.moodTrends
                              .map((e) => FlSpot(e.day.toDouble(), e.score))
                              .toList(),
                          isCurved: true,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) => Text('${value.toInt()}日'),
                            reservedSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('📈 思い込みと気分スコアの関係', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('思い込み')),
                      Padding(padding: EdgeInsets.all(8), child: Text('回数')),
                      Padding(padding: EdgeInsets.all(8), child: Text('平均スコア')),
                    ]),
                    for (final stat in report.biasStats)
                      TableRow(children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(stat.bias)),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${stat.count}')),
                        Padding(padding: const EdgeInsets.all(8), child: Text('${stat.avgScore}')),
                      ])
                  ],
                ),
                const SizedBox(height: 24),

                Text('🧠 気づきと問いかけ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Text(
                    '「${report.insight.bias}」は${report.insight.count}回出現し、その日の気分スコアは平均${report.insight.avgScore}でした。\n\n'
                    '例：「${report.insight.example}」\n\n'
                    '${report.insight.comment}\n\n'
                    '🗨 今月の問い：「${report.insight.question}」',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // 🔼 前面：開発中バナー + 半透明オーバーレイ
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5), // 半透明オーバーレイ
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.construction, color: Colors.orange, size: 40),
                  SizedBox(height: 12),
                  Text(
                    '開発中のサンプル画面です',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'この画面は現在開発中のサンプルデータを表示しています。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    /*return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("月次レポート", style: Theme.of(context).textTheme.headlineSmall),
                //const SizedBox(width: 16),
                const Spacer(), // 左に寄せるための空きスペース
                DropdownButton<String>(
                  value: safeSelectedMonth,
                  items: availableMonths.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text('$month月'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedMonthProvider.notifier).state = value;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('📊 今月のまとめ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('記録数：${report.entryCount}件'),
            Text('平均気分スコア：${report.averageMoodScore}（先月比 ${report.previousMonthDiff}）'),
            Text('よく見られた思い込み：${report.commonBiases.join('、')}'),
            const SizedBox(height: 24),

            Text('📉 気分スコアの推移', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: report.moodTrends
                          .map((e) => FlSpot(e.day.toDouble(), e.score))
                          .toList(),
                      isCurved: true,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}日'),
                        reservedSize: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('📈 思い込みと気分スコアの関係', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('思い込み')),
                  Padding(padding: EdgeInsets.all(8), child: Text('回数')),
                  Padding(padding: EdgeInsets.all(8), child: Text('平均スコア')),
                ]),
                for (final stat in report.biasStats)
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(stat.bias)),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${stat.count}')),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${stat.avgScore}')),
                  ])
              ],
            ),
            const SizedBox(height: 24),

            Text('🧠 気づきと問いかけ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Text(
                '「${report.insight.bias}」は${report.insight.count}回出現し、その日の気分スコアは平均${report.insight.avgScore}でした。\n\n'
                '例：「${report.insight.example}」\n\n'
                '${report.insight.comment}\n\n'
                '🗨 今月の問い：「${report.insight.question}」',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );*/
  }
}
