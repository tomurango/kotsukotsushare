import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/answers_provider.dart';
import '../../providers/question_provider.dart';
import '../../services/local_database.dart';
import '../../models/question_unlock_data.dart';

class QuestionAnswersList extends HookConsumerWidget {
  const QuestionAnswersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQuestionIndex = ref.watch(selectedQuestionIndexProvider);
    final questionListAsync = ref.watch(questionsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isQuestionUnlocked = useState<bool?>(null);

    return questionListAsync.when(
      data: (questions) {
        if (selectedQuestionIndex >= questions.length) {
          return const Center(child: Text("無効な質問が選択されています"));
        }

        final questionId = questions[selectedQuestionIndex]["id"];
        final questionIsMine = questions[selectedQuestionIndex]["type"] == "my";

        final answersState = ref.watch(answersProvider(questionId));
        final cachedAnswers = ref.watch(cachedAnswersProvider)[questionId] ?? [];

        // 質問の開封状態をチェック
        useEffect(() {
          _checkQuestionUnlockStatus() async {
            if (currentUser?.uid == null || currentUser!.uid.isEmpty) {
              isQuestionUnlocked.value = false;
              return;
            }
            final unlocked = await LocalDatabase.isQuestionUnlockedBy(questionId, currentUser.uid);
            isQuestionUnlocked.value = unlocked;
          }
          _checkQuestionUnlockStatus();
          return null;
        }, [questionId, currentUser?.uid]);

        // ✅ Cloud Functions の取得完了後、キャッシュに反映
        useEffect(() {
          ref.listen(answersProvider(questionId), (previous, next) {
            next.whenData((answers) {
              ref.read(cachedAnswersProvider.notifier).updateAnswers(questionId, answers);
            });
          });
          return null;
        }, [questionId]);

        // ✅ 表示ロジック：キャッシュベースで描画
        if (cachedAnswers.isEmpty && answersState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cachedAnswers.isEmpty && answersState.hasError) {
          return Center(child: Text("エラーが発生しました: ${answersState.error}"));
        }

        // 質問が自分のものでない場合、自分で投稿した質問なら他の人の回答が見れることを伝えるメッセージを表示
        if (!questionIsMine) {
          return const Center(child: Text("自分で投稿した質問のみ、他の誰かの考えを確認できます"));
        }

        if (cachedAnswers.isEmpty) {
          return const Center(child: Text("まだ回答がありません"));
        }

        if (cachedAnswers.length == 1 && cachedAnswers[0]["isMine"] == true) {
          // 自分の回答しかない場合
          return const Center(child: Text("他の人の回答はまだありません"));
        }

        // 開封状態がまだ読み込み中の場合
        if (isQuestionUnlocked.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 質問開封ボタン（未開封の場合のみ表示）
            if (!isQuestionUnlocked.value!)
              _QuestionUnlockButton(
                questionId: questionId,
                currentUserId: currentUser?.uid ?? "",
                onUnlocked: () {
                  isQuestionUnlocked.value = true;
                },
              ),
            // 回答リスト
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cachedAnswers.length,
              itemBuilder: (context, index) {
                final answer = cachedAnswers[index];
                // 自分の回答かどうかを判定
                final isMine = answer["isMine"] == true;
                // 自分の回答の場合、表示しない
                if (isMine) {
                  return const SizedBox.shrink();
                }
                final isBestAnswer = answer["isBestAnswer"] == true;
                final answerId = answer["id"];

                return _AnswerItem(
                  answer: answer,
                  answerId: answerId,
                  questionId: questionId,
                  isBestAnswer: isBestAnswer,
                  questionIsMine: questionIsMine,
                  isQuestionUnlocked: isQuestionUnlocked.value!,
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("質問の取得に失敗しました: $e")),
    );
  }
}

// 質問開封ボタンウィジェット
class _QuestionUnlockButton extends HookWidget {
  final String questionId;
  final String currentUserId;
  final VoidCallback onUnlocked;

  const _QuestionUnlockButton({
    required this.questionId,
    required this.currentUserId,
    required this.onUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocking = useState<bool>(false);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, size: 48, color: Colors.blue),
          const SizedBox(height: 8),
          const Text(
            'この質問の回答を開封しますか？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '開封後、この質問のすべての回答が閲覧可能になります',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isUnlocking.value
                ? null
                : () => _unlockQuestion(context, isUnlocking),
            icon: isUnlocking.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_open),
            label: Text(isUnlocking.value ? '開封中...' : '開封する（100円）'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlockQuestion(
    BuildContext context,
    ValueNotifier<bool> isUnlocking,
  ) async {
    try {
      // 確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('質問を開封'),
          content: const Text('この質問の回答を開封しますか？\n開封料：100円\n（60円が貢献度プールに入り、回答者に分配されます）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('開封する'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isUnlocking.value = true;

      // Cloud Functions で開封処理
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('unlockQuestion');

      final response = await callable.call({
        'questionId': questionId,
      });

      // 開封記録をローカルに保存
      final unlockId = response.data['unlockId'];
      final poolAmount = response.data['poolAmount'];

      final unlockData = QuestionUnlockData(
        id: unlockId,
        questionId: questionId,
        unlockedBy: currentUserId,
        amount: 100,
        createdAt: DateTime.now(),
      );

      await LocalDatabase.insertQuestionUnlock(unlockData);

      // 開封状態を更新
      onUnlocked();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('質問を開封しました（貢献度プール：${poolAmount}円）'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('開封に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isUnlocking.value = false;
    }
  }
}

// 回答アイテムウィジェット（質問開封モデル）
class _AnswerItem extends HookConsumerWidget {
  final Map<String, dynamic> answer;
  final String answerId;
  final String questionId;
  final bool isBestAnswer;
  final bool questionIsMine;
  final bool isQuestionUnlocked;

  const _AnswerItem({
    required this.answer,
    required this.answerId,
    required this.questionId,
    required this.isBestAnswer,
    required this.questionIsMine,
    required this.isQuestionUnlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answerText = answer["text"] ?? "";
    final shouldShowPreview = !isQuestionUnlocked && !isBestAnswer;
    final displayText = shouldShowPreview && answerText.length > 50
        ? answerText.substring(0, 50) + "..."
        : answerText;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isBestAnswer ? Colors.green[50] : Colors.grey[200],
        border: isBestAnswer ? Border.all(color: Colors.green, width: 2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBestAnswer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ベストアンサー',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 16,
              color: shouldShowPreview ? Colors.grey[600] : Colors.black,
            ),
          ),
          // ベストアンサー選択ボタン（開封済み かつ ベストアンサー未選択の場合のみ表示）
          if (!isBestAnswer && questionIsMine && isQuestionUnlocked)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _selectBestAnswer(context, ref),
                icon: const Icon(Icons.star_border, size: 16),
                label: const Text('ベストアンサーに選ぶ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectBestAnswer(BuildContext context, WidgetRef ref) async {
    try {
      // 確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ベストアンサー選択'),
          content: const Text('この回答をベストアンサーとして選択しますか？\n選択後は変更できません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('選択する'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Cloud Functions でベストアンサーを設定
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('selectBestAnswer');

      await callable.call({
        'questionId': questionId,
        'answerId': answerId,
      });

      // キャッシュの更新
      final currentAnswers = ref.read(cachedAnswersProvider)[questionId] ?? [];
      final updatedAnswers = currentAnswers.map((answer) {
        if (answer["id"] == answerId) {
          return {...answer, "isBestAnswer": true};
        } else {
          return {...answer, "isBestAnswer": false};
        }
      }).toList();

      ref.read(cachedAnswersProvider.notifier).updateAnswers(questionId, updatedAnswers);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ベストアンサーを選択しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ベストアンサーの選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
