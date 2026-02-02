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
  final tagController = TextEditingController();
  List<String> selectedTags = [];
  List<String> allTags = [];
  bool _showAllTags = false;

  @override
  void initState() {
    super.initState();
    // 編集時は既存データをセット
    if (widget.memo != null) {
      contentController.text = widget.memo!.content;
      selectedTags = List.from(widget.memo!.tags);
    }
    _loadAllTags();
  }

  Future<void> _loadAllTags() async {
    // ローカルDBから取得（使用回数順）
    final tags = await LocalDatabase.getAllTags();
    setState(() {
      allTags = tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isEditing = widget.memo != null;

    return GestureDetector(
      onTap: () {
        // 空白部分タップでフォーカス解除
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 16.0,
        ),
        child: SingleChildScrollView(
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
          // タグセクション
          Text(
            'タグ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          // 選択中のタグ表示
          if (selectedTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedTags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  deleteIcon: Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      selectedTags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          if (selectedTags.isNotEmpty) SizedBox(height: 8),
          // 既存タグから選択
          if (allTags.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '既存のタグから選択',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (allTags.length > 5)
                  TextButton.icon(
                    icon: Icon(
                      _showAllTags ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      _showAllTags ? '閉じる' : 'もっと見る (${allTags.length}個)',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _showAllTags = !_showAllTags;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (_showAllTags ? allTags : allTags.take(5))
                  .where((tag) => !selectedTags.contains(tag))
                  .map((tag) {
                return ActionChip(
                  label: Text(tag),
                  onPressed: () {
                    setState(() {
                      selectedTags.add(tag);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 8),
          ],
          // 新規タグ追加
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    labelText: '新しいタグを追加',
                    hintText: '例：仕事、勉強、趣味',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (value) => _addNewTag(),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addNewTag,
                tooltip: 'タグを追加',
              ),
            ],
          ),
          SizedBox(height: 8),
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
        ),
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
          tags: selectedTags,
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
          'tags': selectedTags,
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

  void _addNewTag() {
    final newTag = tagController.text.trim();
    if (newTag.isNotEmpty && !selectedTags.contains(newTag)) {
      setState(() {
        selectedTags.add(newTag);
        if (!allTags.contains(newTag)) {
          allTags.add(newTag);
          allTags.sort();
        }
      });
      tagController.clear();
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    tagController.dispose();
    super.dispose();
  }
}
