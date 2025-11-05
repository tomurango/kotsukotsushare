import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/local_data_provider.dart';
import '../providers/card_memos_provider.dart';
import '../services/local_database.dart';
import '../models/memo_data.dart';
import '../widgets/standalone_memo_bottom_sheet.dart';

class MypageScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  MypageScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final memosAsyncValue = ref.watch(unifiedStandaloneMemosProvider);
    final viewMode = ref.watch(standaloneMemoViewModeProvider);

    // 日付のフォーマット
    String formatDate(DateTime date) {
      final DateFormat formatter = DateFormat('yyyy/MM/dd');
      return formatter.format(date);
    }

    return Scaffold(
      body: Column(
        children: [
          // 表示モード切り替えボタン
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '表示モード:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<MemoViewMode>(
                    segments: [
                      ButtonSegment(
                        value: MemoViewMode.chronological,
                        label: Text('時系列'),
                        icon: Icon(Icons.access_time, size: 18),
                      ),
                      ButtonSegment(
                        value: MemoViewMode.tags,
                        label: Text('タグ分類'),
                        icon: Icon(Icons.label, size: 18),
                      ),
                    ],
                    selected: {viewMode},
                    onSelectionChanged: (Set<MemoViewMode> newSelection) {
                      ref.read(standaloneMemoViewModeProvider.notifier).state = newSelection.first;
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: memosAsyncValue.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'メモはありません',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '右下の＋ボタンからメモを作成しましょう',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // 表示モードに応じて異なるビューを返す
                if (viewMode == MemoViewMode.chronological) {
                  return _buildChronologicalView(context, ref, memos, formatDate);
                } else {
                  return _buildTagsView(context, ref, memos, formatDate);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return StandaloneMemoBottomSheet();
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF008080),
      ),
    );
  }

  // 時系列表示
  Widget _buildChronologicalView(
    BuildContext context,
    WidgetRef ref,
    List<MemoData> memos,
    String Function(DateTime) formatDate,
  ) {
    return ListView.builder(
      itemCount: memos.length,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        final memo = memos[index];

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日付
                Text(
                  formatDate(memo.createdAt),
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: 8),
                // メモ内容
                Text(
                  memo.content,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // タグ表示
                if (memo.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: memo.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue[50],
                        side: BorderSide(color: Colors.blue[200]!),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 8),
                ],

                // アクションボタン
                Row(
                  children: [
                    // タグ編集ボタン
                    TextButton.icon(
                      icon: Icon(Icons.label, size: 14, color: Colors.grey[600]),
                      label: Text(
                        'タグ編集',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.only(left: 0, right: 8, top: 4, bottom: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showTagEditDialog(context, ref, memo),
                    ),
                    Spacer(),
                    // その他のメニュー
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editMemo(context, memo);
                            break;
                          case 'delete':
                            _deleteMemo(context, ref, memo);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(value: 'edit', child: Text('編集')),
                        PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // タグ分類表示
  Widget _buildTagsView(
    BuildContext context,
    WidgetRef ref,
    List<MemoData> memos,
    String Function(DateTime) formatDate,
  ) {
    // タグごとにメモをグループ化
    Map<String, List<MemoData>> groupedMemos = {};

    for (var memo in memos) {
      if (memo.tags.isEmpty) {
        groupedMemos.putIfAbsent('未分類', () => []).add(memo);
      } else {
        for (var tag in memo.tags) {
          groupedMemos.putIfAbsent(tag, () => []).add(memo);
        }
      }
    }

    final sortedTags = groupedMemos.keys.toList()
      ..sort((a, b) {
        if (a == '未分類') return 1;
        if (b == '未分類') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      itemCount: sortedTags.length,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        final tag = sortedTags[index];
        final tagMemos = groupedMemos[tag]!;

        return ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(
            tag == '未分類' ? Icons.label_off : Icons.label,
            color: tag == '未分類' ? Colors.grey : Colors.blue,
          ),
          title: Text(
            '$tag (${tagMemos.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tag == '未分類' ? Colors.grey : Colors.black87,
            ),
          ),
          children: tagMemos.map((memo) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(56.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      formatDate(memo.createdAt),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Text(
                      memo.content,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.edit_note, size: 16),
                          label: Text('タグ編集'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.only(left: 0, right: 8, top: 4, bottom: 4),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showTagEditDialog(context, ref, memo),
                        ),
                        Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editMemo(context, memo);
                                break;
                              case 'delete':
                                _deleteMemo(context, ref, memo);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(value: 'edit', child: Text('編集')),
                            PopupMenuItem(value: 'delete', child: Text('削除')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // タグ編集ダイアログ
  void _showTagEditDialog(BuildContext context, WidgetRef ref, MemoData memo) {
    final TextEditingController tagController = TextEditingController();
    final selectedTags = List<String>.from(memo.tags);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('タグを編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedTags.isNotEmpty) ...[
                      Text('現在のタグ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                selectedTags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],
                    Text('新しいタグを追加:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: tagController,
                      decoration: InputDecoration(
                        hintText: 'タグ名を入力',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            final newTag = tagController.text.trim();
                            if (newTag.isNotEmpty && !selectedTags.contains(newTag)) {
                              setState(() {
                                selectedTags.add(newTag);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        final newTag = value.trim();
                        if (newTag.isNotEmpty && !selectedTags.contains(newTag)) {
                          setState(() {
                            selectedTags.add(newTag);
                            tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    final updatedMemo = memo.copyWith(tags: selectedTags);
                    await _updateMemoTags(context, ref, updatedMemo);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // メモのタグを更新
  Future<void> _updateMemoTags(BuildContext context, WidgetRef ref, MemoData memo) async {
    try {
      final useLocal = ref.read(useLocalDataProvider);

      if (useLocal) {
        await LocalDatabase.updateMemo(memo);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('cards')
            .doc(STANDALONE_CARD_ID)
            .collection('memos')
            .doc(memo.id)
            .update({
          'tags': memo.tags,
          'updatedAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タグを更新しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('タグの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // メモ編集
  void _editMemo(BuildContext context, MemoData memo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StandaloneMemoBottomSheet(memo: memo);
      },
    );
  }

  // メモ削除
  Future<void> _deleteMemo(BuildContext context, WidgetRef ref, MemoData memo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('メモの削除'),
          content: Text('このメモを削除しますか？', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('削除', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final useLocal = ref.read(useLocalDataProvider);

        if (useLocal) {
          await LocalDatabase.deleteMemo(memo.id);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('cards')
              .doc(STANDALONE_CARD_ID)
              .collection('memos')
              .doc(memo.id)
              .delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('メモを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
