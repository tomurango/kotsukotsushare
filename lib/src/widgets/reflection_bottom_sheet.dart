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
  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初期データをセット
    contentController.text = widget.memo.content;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.memo.id.isEmpty ? '新しいメモ' : 'メモを編集',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: contentController,
            decoration: InputDecoration(
              labelText: 'メモの内容',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            autofocus: widget.memo.id.isEmpty, // 新規作成時は自動フォーカス
          ),
          SizedBox(height: 16),
          Text(
            '※ メモは公開されません',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('メモの内容を入力してください')),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  final memosCollection = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('cards')
                      .doc(widget.cardId)
                      .collection('memos');

                  // 保存データを構築（シンプル化）
                  final memoData = {
                    'content': contentController.text.trim(),
                    'type': '', // 空文字（カテゴリなし）
                    'feeling': '', // 後方互換性のため保持
                    'truth': '', // 後方互換性のため保持
                    'updatedAt': Timestamp.now(),
                  };

                  try {
                    if (widget.memo.id.isNotEmpty) {
                      // 上書き更新
                      await memosCollection.doc(widget.memo.id).update(memoData);
                    } else {
                      // 新規作成
                      memoData['createdAt'] = Timestamp.now();
                      memoData['userId'] = user.uid;
                      await memosCollection.add(memoData);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.memo.id.isEmpty ? 'メモを作成しました' : 'メモを更新しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('保存に失敗しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.memo.id.isEmpty ? 'メモを保存' : '変更を保存',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
