import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';

final availableMonths = [
  '2025-04',
  '2025-03',
  '2025-02',
];

// 選択中の月（state）
final selectedMonthProvider = StateProvider<String>((ref) => availableMonths.first);

// 月ごとのレポートデータ（仮のダミーデータ使用）
final reportProvider = Provider<MonthlyReport>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);

  // Firestore取得処理の代わりに月によって違うダミーデータ返却
  if (selectedMonth == '2025-04') {
    return MonthlyReport.mockApril();
  } else if (selectedMonth == '2025-03') {
    return MonthlyReport.mockMarch();
  } else {
    return MonthlyReport.mockFebruary();
  }
});
