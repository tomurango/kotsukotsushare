// lib/widgets/question/question_appbar_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../providers/question_provider.dart';

class QuestionAppBarMenu extends ConsumerWidget {
  const QuestionAppBarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(questionsProvider);
    final selectedIndex = ref.watch(selectedQuestionIndexProvider);
    
    return questionsState.when(
      data: (questions) {
        if (questions.isEmpty || selectedIndex >= questions.length) return const SizedBox();

        final question = questions[selectedIndex];
        final isMine = question["type"] == "my";
        final questionId = question["id"];

        return isMine
            ? const SizedBox.shrink()
            : PopupMenuButton<String>(
            icon: Icon(
                // isMine ? Icons.edit_note : Icons.more_vert,
                Icons.more_vert,
                color: Colors.white,
            ),
            tooltip: isMine ? "投稿の操作" : "このユーザーに関する操作", // ← Tooltipで補足
            onSelected: (value) {
                switch (value) {
                case 'edit':
                    // 編集モーダルを表示 or 遷移
                    break;
                case 'toggle_visibility':
                    // 公開設定の切り替え
                    break;
                case 'block':
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                        title: const Text("ブロックの確認"),
                        content: const Text("この質問の投稿者をブロックしますか？"),
                        actions: [
                            TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("キャンセル"),
                            ),
                            TextButton(
                                onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context); // ← 先に取得しておく
                                    Navigator.pop(context); // context が使えなくなる前に閉じる

                                    try {
                                    final callable = FirebaseFunctions.instance.httpsCallable("blockUserByQuestionId");
                                    await callable.call({
                                        "questionId": questionId,
                                    });

                                    messenger.showSnackBar(
                                        const SnackBar(content: Text("完了しました")),
                                    );
                                    } catch (e) {
                                    messenger.showSnackBar(
                                        SnackBar(content: Text("エラー: $e")),
                                    );
                                    }
                                },
                                child: const Text("ブロックする", style: TextStyle(color: Colors.red)),
                            ),
                        ],
                        ),
                    );
                    break;
                case 'report':
                    showReportDialog(context, questionId);
                    break;
                }
            },
            itemBuilder: (context) {
                if (isMine) {
                return [
                    const PopupMenuItem(value: 'edit', child: Text('編集')),
                    const PopupMenuItem(value: 'toggle_visibility', child: Text('公開設定の変更')),
                ];
                } else {
                return [
                    const PopupMenuItem(value: 'block', child: Text('この質問をブロック')),
                    const PopupMenuItem(value: 'report', child: Text('通報する')),
                ];
                }
            },
        );

      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  void showReportDialog(BuildContext context, String questionId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text("通報の確認"),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text("この質問を通報しますか？"),
            const SizedBox(height: 12),
            TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                hintText: "通報理由を入力してください",
                border: OutlineInputBorder(),
                ),
            ),
            ],
        ),
        actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
            ),
            TextButton(
            onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final reason = reasonController.text.trim();
                Navigator.pop(context); // 先に閉じる

                if (reason.isEmpty) {
                messenger.showSnackBar(
                    const SnackBar(content: Text("理由を入力してください")),
                );
                return;
                }

                try {
                final callable = FirebaseFunctions.instance.httpsCallable("reportQuestion");
                await callable.call({
                    "questionId": questionId,
                    "reason": reason,
                });

                messenger.showSnackBar(
                    const SnackBar(content: Text("通報が送信されました")),
                );
                } catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text("エラー: $e")),
                );
                }
            },
            child: const Text("通報する", style: TextStyle(color: Colors.red)),
            ),
        ],
        ),
    );
  }
}
