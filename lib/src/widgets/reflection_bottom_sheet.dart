import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memo_data.dart';
import '../providers/card_memos_provider.dart';

class ReflectionBottomSheet extends ConsumerStatefulWidget {
  final MemoData memo;
  final String cardId;

  ReflectionBottomSheet({required this.memo, required this.cardId});

  @override
  _ReflectionBottomSheetState createState() => _ReflectionBottomSheetState();
}


class _ReflectionBottomSheetState extends ConsumerState<ReflectionBottomSheet> {
  int selectedSegment = 0;

  final contentController = TextEditingController();
  final feelingController = TextEditingController();
  final truthController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 初期データをセット
    contentController.text = widget.memo.content;
    if (widget.memo.type == 'reflection') {
      feelingController.text = widget.memo.feeling ?? '';
      truthController.text = widget.memo.truth ?? '';
      selectedSegment = 1; // reflectionモードにセット
    } else {
      selectedSegment = 0; // memoモードにセット
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublic = ref.watch(isPublicProvider);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToggleButtons(
            isSelected: [selectedSegment == 0, selectedSegment == 1],
            onPressed: (int index) {
              setState(() {
                selectedSegment = index;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('メモ'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('内省'),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (selectedSegment == 0) ...[
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'メモの内容',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: '内省の内容 (何があったか)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: feelingController,
              decoration: InputDecoration(
                labelText: 'どう感じたか',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: truthController,
              decoration: InputDecoration(
                labelText: '面白い真実は何か',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('公開 / 非公開'),
              Row(
                children: [
                  // 現在の公開・非公開状態をテキストで表示
                  Text(isPublic ? '公開中' : '非公開中'),
                  SizedBox(width: 8), // ラベルとスイッチの間にスペースを追加
                  Switch(
                    value: isPublic,
                    onChanged: (value) {
                      // RiverpodのStateProviderで状態を更新
                      ref.read(isPublicProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user != null) {
                final memosCollection = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('cards')
                    .doc(widget.cardId)
                    .collection('memos');

                // 上書きデータを構築
                final updatedData = {
                  'content': contentController.text,
                  'isPublic': isPublic,
                  'type': selectedSegment == 0 ? 'memo' : 'reflection',
                  'updatedAt': Timestamp.now(),
                };

                if (selectedSegment == 1) {
                  updatedData['feeling'] = feelingController.text;
                  updatedData['truth'] = truthController.text;
                }

                try {
                  if (widget.memo.id.isNotEmpty) {
                    // 上書き更新: idが存在する場合
                    await memosCollection.doc(widget.memo.id).update(updatedData);
                    print('メモを上書きしました');
                  } else {
                    // 新規作成: idが空の場合
                    updatedData['createdAt'] = Timestamp.now();
                    updatedData['userId'] = user.uid;
                    await memosCollection.add(updatedData);
                    print('新規メモを作成しました');
                  }

                  Navigator.pop(context); // ボトムシートを閉じる
                } catch (e) {
                  print('エラーが発生しました: $e');
                }
              }
            },
            child: Text('保存'),
          ),

          if (isKeyboardVisible)
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
