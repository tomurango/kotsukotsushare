import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_provider.dart';

class QuestionBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(isExpandedProvider);
    final selectedQuestionIndexNotifier = ref.read(selectedQuestionIndexProvider.notifier);
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final questionState = ref.watch(questionsProvider);

    return questionState.when(
      data: (questionsData) {
        // 🔹 もし `questionsData` が空なら BottomSheet を非表示にする
        if (questionsData.isEmpty) {
          return SizedBox.shrink();
        }

        // 🔹 省略表示時は最大 5 件まで表示
        final visibleQuestions = isExpanded
            ? questionsData // 🔥 展開時は全件表示
            : questionsData.take(5).toList(); // 🔥 省略時は最大 5 件

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: isExpanded ? MediaQuery.of(context).size.height * 0.4 : 100,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 4)],
          ),
          child: Column(
            children: [
              if (!isExpanded)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleQuestions.length + 1, // 🔥 `expand_more` を加える
                    itemBuilder: (context, index) {
                      if (index == visibleQuestions.length) {

                        // BottomSheetを開くボタン
                        return GestureDetector(
                            onTap: () {
                                ref.read(isExpandedProvider.notifier).state = true;
                            },
                            child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // 🔹 高さをコンパクトに調整
                                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8), // 🔹 上下の余白を追加
                                decoration: BoxDecoration(
                                    color: Colors.grey[300], // 🔥 選択時の色を少し濃く
                                    borderRadius: BorderRadius.circular(12), // 🔹 丸みを追加
                                    border: null,
                                ),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.keyboard_arrow_up, color: Colors.grey[600], size: 18), // 🔥 選択中のアイコンを追加
                                        SizedBox(width: 6),
                                        Text(
                                            "開く",
                                            style: TextStyle(
                                                fontSize: 14, // 🔹 文字サイズを微調整
                                                fontWeight: FontWeight.bold, // 🔹 文字を少し太く
                                                color: Colors.grey[600],
                                            ),
                                        ),
                                        SizedBox(width: 6),
                                    ],
                                ),
                            ),
                        );
                      }

                      final question = visibleQuestions[index];
                      final selectedId = question["id"];
                      final newIndex = questionsData.indexWhere((q) => q["id"] == selectedId);

                      return GestureDetector(
                        onTap: () {
                            if (newIndex != -1) {
                            selectedQuestionIndexNotifier.state = newIndex;
                            }
                        },
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // 🔹 高さをコンパクトに調整
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8), // 🔹 上下の余白を追加
                            decoration: BoxDecoration(
                            color: selectedQuestionIndex == newIndex ? Color(0xFF006666) : Colors.grey[300], // 🔥 選択時の色を少し濃く
                            borderRadius: BorderRadius.circular(12), // 🔹 丸みを追加
                            border: selectedQuestionIndex == newIndex 
                                ? Border.all(color: Colors.white, width: 4) // 🔥 選択中はボーダーをつける
                                : null,
                            ),
                            child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                if (selectedQuestionIndex == newIndex) ...[
                                Icon(Icons.check_circle, color: Colors.white, size: 18), // 🔥 選択中のアイコンを追加
                                SizedBox(width: 6),
                                ],
                                Text(
                                question["question"] ?? "質問なし",
                                style: TextStyle(
                                    fontSize: 14, // 🔹 文字サイズを微調整
                                    fontWeight: FontWeight.bold, // 🔹 文字を少し太く
                                    color: selectedQuestionIndex == newIndex ? Colors.white : Colors.black,
                                ),
                                ),
                            ],
                            ),
                        ),
                      );

                      
                    },
                  ),
                ),

              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Row(
                    // 右側に閉じるボタンを追加
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                        TextButton.icon(
                            onPressed: () => ref.read(isExpandedProvider.notifier).state = false,
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Colors.grey[300]), // 🔹 背景色を灰色
                                foregroundColor: MaterialStateProperty.all(Colors.black54), // 🔹 文字色
                                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8)), // 🔹 余白
                                shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // 🔹 角丸
                                ),
                                ),
                                overlayColor: MaterialStateProperty.all(Colors.grey[400]), // 🔥 押した時のエフェクト
                                elevation: MaterialStateProperty.all(2), // 🔹 立体感を追加
                            ),
                            icon: Icon(Icons.keyboard_arrow_down, size: 24), // 🔥 視認性の高いアイコン
                            label: Text("閉じる"), // 🔹 "閉じる" のテキストを追加
                        ),
                    ],
                  ),
                ),

              if (isExpanded)
                Expanded(
                  child: ListView.builder(
                    itemCount: questionsData.length,
                    itemBuilder: (context, index) {
                      final question = questionsData[index];


                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                            color: selectedQuestionIndex == index ? Color(0xFF008080) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selectedQuestionIndex == index
                                ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                                : [],
                        ),
                        child: ListTile(
                            title: Text(
                            question["question"] ?? "質問なし",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: selectedQuestionIndex == index ? Colors.white : Colors.black87,
                            ),
                            ),
                            leading: selectedQuestionIndex == index
                                ? Icon(Icons.check_circle, color: Colors.white)
                                : null,
                            trailing: _buildQuestionTypeChip(question["type"]), // 🔹 チップを追加
                            onTap: () => selectedQuestionIndexNotifier.state = index,
                        ),
                        );

                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text("エラーが発生しました: $error")),
    );
  }

  Widget _buildQuestionTypeChip(String? type) {
  return Chip(
    label: Text(
      _getChipLabel(type),
      style: TextStyle(
        fontSize: 12,
        fontWeight: type == "random" ? FontWeight.bold : FontWeight.normal,
        fontStyle: type == "favorite" ? FontStyle.italic : FontStyle.normal,
        color: Colors.black87,
      ),
    ),
    backgroundColor: Colors.grey[300] ?? Colors.grey[200], // 🔹 `null` チェックを追加
    side: BorderSide(color: Colors.grey[500] ?? Colors.grey), // 🔹 `null` チェックを追加
    visualDensity: VisualDensity.compact,
  );
}


String _getChipLabel(String? type) {
  switch (type) {
    case "random":
      return "ランダム";
    case "my":
      return "自分の投稿";
    case "favorite":
      return "お気に入り";
    default:
      return "その他";
  }
}


}
