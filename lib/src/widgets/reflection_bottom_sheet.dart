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
  // モード切り替え用のインデックス（0がメモ、1が内省）
  int selectedSegment = 0;

  // テキストフィールド用のコントローラ
  final contentController = TextEditingController();
  final feelingController = TextEditingController();
  final truthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Riverpodで管理されているisPublicの状態を監視
    final isPublic = ref.watch(isPublicProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ToggleButtonsでメモと内省を切り替え
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

          // 選択されたセグメントに応じてフォームを表示
          if (selectedSegment == 0) ...[
            // メモ用のフォーム
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'メモの内容',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            // 内省用のフォーム
            TextField(
              controller: contentController, // 内省の内容もcontentフィールドに保存
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

          // 公開・非公開の切り替えスイッチ
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

          // 保存ボタン
          ElevatedButton(
            onPressed: () {
              // 選択されたセグメントに応じてデータを保存
              if (selectedSegment == 0) {
                // メモの保存処理
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('cards')
                    .doc(widget.cardId)
                    .collection('memos')
                    .add({
                  'content': contentController.text, // メモと内省共通でcontentを使用
                  'type': 'memo',
                  'createdAt': Timestamp.now(),
                  'isPublic': isPublic, // 公開・非公開のフラグ
                  'userId': FirebaseAuth.instance.currentUser!.uid,
                });
              } else {
                // 内省の保存処理
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('cards')
                    .doc(widget.cardId)
                    .collection('memos')
                    .add({
                  'content': contentController.text, // 内省の内容もcontentに保存
                  'feeling': feelingController.text,  // どう感じたか
                  'truth': truthController.text,      // 面白い真実は何か
                  'type': 'reflection',
                  'createdAt': Timestamp.now(),
                  'isPublic': isPublic, // 公開・非公開のフラグ
                  'userId': FirebaseAuth.instance.currentUser!.uid,
                });
              }

              // ボトムシートを閉じる
              Navigator.pop(context);
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}
