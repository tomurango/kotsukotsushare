import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memo_data.dart';
import '../providers/card_memos_provider.dart';
import '../providers/local_data_provider.dart';
import '../services/local_database.dart';

class StandaloneMemoBottomSheet extends ConsumerStatefulWidget {
  final MemoData? memo; // 編集時は既存のメモ、新規作成時はnull

  StandaloneMemoBottomSheet({this.memo});

  @override
  _StandaloneMemoBottomSheetState createState() => _StandaloneMemoBottomSheetState();
}

class _StandaloneMemoBottomSheetState extends ConsumerState<StandaloneMemoBottomSheet> {
  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 編集時は既存データをセット
    if (widget.memo != null) {
      contentController.text = widget.memo!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isEditing = widget.memo != null;

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
            isEditing ? 'メモを編集' : '新しいメモ',
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
            autofocus: !isEditing, // 新規作成時は自動フォーカス
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

                await _saveMemo(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isEditing ? '変更を保存' : 'メモを保存',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMemo(BuildContext context) async {
    final useLocal = ref.read(useLocalDataProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ユーザー情報が取得できません')),
      );
      return;
    }

    try {
      if (useLocal) {
        // ローカルデータベースに保存
        final memo = MemoData(
          id: widget.memo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          cardId: STANDALONE_CARD_ID,
          content: contentController.text.trim(),
          createdAt: widget.memo?.createdAt ?? DateTime.now(),
          type: '',
          feeling: '',
          truth: '',
          tags: widget.memo?.tags ?? [],
        );

        if (widget.memo != null) {
          await LocalDatabase.updateMemo(memo);
        } else {
          await LocalDatabase.insertMemo(memo);
        }
      } else {
        // Firestoreに保存
        final memosCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .doc(STANDALONE_CARD_ID)
            .collection('memos');

        final memoData = {
          'content': contentController.text.trim(),
          'type': '',
          'feeling': '',
          'truth': '',
          'tags': widget.memo?.tags ?? [],
          'updatedAt': Timestamp.now(),
        };

        if (widget.memo != null) {
          // 更新
          await memosCollection.doc(widget.memo!.id).update(memoData);
        } else {
          // 新規作成
          memoData['createdAt'] = Timestamp.now();
          memoData['userId'] = user.uid;
          await memosCollection.add(memoData);
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.memo != null ? 'メモを更新しました' : 'メモを作成しました'),
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

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}
