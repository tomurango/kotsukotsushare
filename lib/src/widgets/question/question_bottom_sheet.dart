import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_provider.dart';

class QuestionBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(isExpandedProvider);
    final showMyQuestions = ref.watch(showMyQuestionsProvider);
    final showAllQuestions = ref.watch(showAllQuestionsProvider);
    final selectedQuestionIndexNotifier = ref.read(selectedQuestionIndexProvider.notifier);
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final allQuestions = ref.watch(questionsProvider);

    // フィルタリング
    List<Map<String, String>> filteredQuestions = [];
    if (showAllQuestions) {
      filteredQuestions.addAll(allQuestions.where((q) => q["type"] == "public"));
    }
    if (showMyQuestions) {
      filteredQuestions.addAll(allQuestions.where((q) => q["type"] == "private"));
    }

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
                itemCount: filteredQuestions.length > 5 ? 6 : filteredQuestions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 5 || index == filteredQuestions.length) {
                    return GestureDetector(
                      onTap: () => ref.read(isExpandedProvider.notifier).state = true,
                      child: Container(
                        width: 60,
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF008080),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.expand_more, color: Colors.white),
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => selectedQuestionIndexNotifier.state = index,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: selectedQuestionIndex == index
                            ? Color(0xFF008080)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          filteredQuestions[index]["question"]!,
                          style: TextStyle(
                            color: selectedQuestionIndex == index ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // 🔥 この Row を Expanded で囲む
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded( // 🔥 ボタンごとに均等配置
                          child: TextButton.icon(
                            onPressed: () =>
                                ref.read(showMyQuestionsProvider.notifier).state = !showMyQuestions,
                            icon: Icon(
                              showMyQuestions ? Icons.check_box : Icons.check_box_outline_blank,
                              color: showMyQuestions ? Colors.green : Colors.grey,
                            ),
                            label: Text("自分の質問", overflow: TextOverflow.ellipsis), // 🔥 長すぎたら省略
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () =>
                                ref.read(showAllQuestionsProvider.notifier).state = !showAllQuestions,
                            icon: Icon(
                              showAllQuestions ? Icons.check_box : Icons.check_box_outline_blank,
                              color: showAllQuestions ? Colors.green : Colors.grey,
                            ),
                            label: Text("みんなの質問", overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => ref.read(isExpandedProvider.notifier).state = false,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(32, 32), // 🔥 ボタンサイズを小さく
                      padding: EdgeInsets.zero, // 🔥 内側の余白をなくす
                      shape: CircleBorder(), // 🔥 丸ボタンにする
                    ),
                    child: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),

          if (isExpanded)
            Expanded(
              child: ListView.builder(
                itemCount: filteredQuestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredQuestions[index]["question"]!),
                    tileColor: selectedQuestionIndex == index
                        ? Color(0xFF008080)
                        : Colors.transparent,
                    textColor: selectedQuestionIndex == index ? Colors.white : Colors.black,
                    onTap: () => selectedQuestionIndexNotifier.state = index,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
