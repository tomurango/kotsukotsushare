import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/local_data_provider.dart';
import '../providers/card_memos_provider.dart';
import '../services/local_database.dart';
import '../models/memo_data.dart';
import '../widgets/standalone_memo_bottom_sheet.dart';

// タグの展開状態を管理するプロバイダー
final tagExpansionStateProvider = StateProvider<Map<String, bool>>((ref) => {});

// タグ展開状態のバージョン管理（強制リビルド用）
final tagExpansionVersionProvider = StateProvider<int>((ref) => 0);

// 利用可能なアイコンリスト
final availableTagIcons = {
  'label': Icons.label,
  'work': Icons.work,
  'school': Icons.school,
  'sports_soccer': Icons.sports_soccer,
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'book': Icons.book,
  'favorite': Icons.favorite,
  'home': Icons.home,
  'flight': Icons.flight,
  'music_note': Icons.music_note,
  'sports_esports': Icons.sports_esports,
  'fitness_center': Icons.fitness_center,
  'palette': Icons.palette,
  'camera_alt': Icons.camera_alt,
  'pets': Icons.pets,
};

// タグアイコンを管理するプロバイダー
class TagIconNotifier extends StateNotifier<Map<String, String>> {
  TagIconNotifier() : super({}) {
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('tag_icon_'));
    final icons = <String, String>{};
    for (var key in keys) {
      final tag = key.replaceFirst('tag_icon_', '');
      final iconKey = prefs.getString(key);
      if (iconKey != null) {
        icons[tag] = iconKey;
      }
    }
    state = icons;
  }

  Future<void> setIcon(String tag, String iconKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tag_icon_$tag', iconKey);
    state = {...state, tag: iconKey};
  }

  IconData getIcon(String tag) {
    final iconKey = state[tag];
    if (iconKey != null && availableTagIcons.containsKey(iconKey)) {
      return availableTagIcons[iconKey]!;
    }
    return tag == '未分類' ? Icons.label_off : Icons.label;
  }
}

final tagIconProvider = StateNotifierProvider<TagIconNotifier, Map<String, String>>((ref) {
  return TagIconNotifier();
});

// タグの並び順を管理するプロバイダー
class TagOrderNotifier extends StateNotifier<List<String>> {
  TagOrderNotifier() : super([]) {
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList('tag_order') ?? [];
    state = order;
  }

  Future<void> saveOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tag_order', order);
    state = order;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final newOrder = List<String>.from(state);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    await saveOrder(newOrder);
  }
}

final tagOrderProvider = StateNotifierProvider<TagOrderNotifier, List<String>>((ref) {
  return TagOrderNotifier();
});

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
            child: Column(
              children: [
                Row(
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
                // タグ分類モードの時のみ、一括展開/折りたたみボタンを表示
                if (viewMode == MemoViewMode.tags) ...[
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.unfold_more, size: 18),
                        label: Text('全て展開', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final memos = ref.read(unifiedStandaloneMemosProvider).value ?? [];
                          _expandAllTags(ref, memos);
                        },
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        icon: Icon(Icons.unfold_less, size: 18),
                        label: Text('全て閉じる', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final memos = ref.read(unifiedStandaloneMemosProvider).value ?? [];
                          _collapseAllTags(ref, memos);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '全て閉じると並び替えできます',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
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

    // 保存された順番を取得
    final savedOrder = ref.watch(tagOrderProvider);

    // タグをソート（保存された順番がある場合はそれに従う、なければアルファベット順）
    final sortedTags = groupedMemos.keys.toList();
    sortedTags.sort((a, b) {
      final aIndex = savedOrder.indexOf(a);
      final bIndex = savedOrder.indexOf(b);

      // 両方とも保存された順番にある場合
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      // aのみ保存された順番にある場合
      if (aIndex != -1) return -1;
      // bのみ保存された順番にある場合
      if (bIndex != -1) return 1;

      // どちらも保存された順番にない場合はデフォルトのソート
      if (a == '未分類') return 1;
      if (b == '未分類') return -1;
      return a.compareTo(b);
    });

    // 新しいタグがあれば、保存された順番に追加
    if (sortedTags.length != savedOrder.length || !sortedTags.every((tag) => savedOrder.contains(tag))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tagOrderProvider.notifier).saveOrder(sortedTags);
      });
    }

    // 展開状態を取得
    final expansionState = ref.watch(tagExpansionStateProvider);
    final expansionVersion = ref.watch(tagExpansionVersionProvider);

    // 全てのタグが閉じているかチェック
    final allTagsClosed = sortedTags.every((tag) => expansionState[tag] == false);

    // 全て閉じている場合のみReorderableListViewを使用
    if (allTagsClosed) {
      return ReorderableListView.builder(
      itemCount: sortedTags.length,
      padding: const EdgeInsets.all(0),
      onReorder: (oldIndex, newIndex) {
        ref.read(tagOrderProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final tag = sortedTags[index];
        final tagMemos = groupedMemos[tag]!;
        final isExpanded = expansionState[tag] ?? true; // デフォルトは展開

        return ExpansionTile(
          key: ValueKey('$tag-$expansionVersion'), // タグとバージョンでユニークなキー
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            // 展開状態を更新
            final currentState = ref.read(tagExpansionStateProvider);
            ref.read(tagExpansionStateProvider.notifier).state = {
              ...currentState,
              tag: expanded,
            };
          },
          leading: GestureDetector(
            onTap: () {
              if (tag != '未分類') {
                _showIconSelectDialog(context, ref, tag);
              }
            },
            child: Icon(
              ref.watch(tagIconProvider.notifier).getIcon(tag),
              color: tag == '未分類' ? Colors.grey : Colors.blue,
            ),
          ),
          title: Text(
            '$tag (${tagMemos.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tag == '未分類' ? Colors.grey : Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
              SizedBox(width: 8),
              Icon(
                Icons.drag_handle,
                color: Colors.grey,
              ),
            ],
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

    // 展開されているタグがある場合は通常のListView（並び替え不可）
    return ListView.builder(
      itemCount: sortedTags.length,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        final tag = sortedTags[index];
        final tagMemos = groupedMemos[tag]!;
        final isExpanded = expansionState[tag] ?? true; // デフォルトは展開

        return ExpansionTile(
          key: ValueKey('$tag-$expansionVersion'), // タグとバージョンでユニークなキー
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            // 展開状態を更新
            final currentState = ref.read(tagExpansionStateProvider);
            ref.read(tagExpansionStateProvider.notifier).state = {
              ...currentState,
              tag: expanded,
            };
          },
          leading: GestureDetector(
            onTap: () {
              if (tag != '未分類') {
                _showIconSelectDialog(context, ref, tag);
              }
            },
            child: Icon(
              ref.watch(tagIconProvider.notifier).getIcon(tag),
              color: tag == '未分類' ? Colors.grey : Colors.blue,
            ),
          ),
          title: Text(
            '$tag (${tagMemos.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tag == '未分類' ? Colors.grey : Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
          children: tagMemos.map((memo) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                dense: true,
                title: Text(
                  memo.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      formatDate(memo.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // タグ編集ダイアログ
  void _showTagEditDialog(BuildContext context, WidgetRef ref, MemoData memo) async {
    final TextEditingController tagController = TextEditingController();
    final selectedTags = List<String>.from(memo.tags);

    // 全タグを読み込み（使用回数順）
    final allTags = await LocalDatabase.getAllTags();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool showAllTags = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('タグを編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 選択中のタグを表示
                    if (selectedTags.isNotEmpty) ...[
                      Text('選択中のタグ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
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
                      SizedBox(height: 16),
                    ],

                    // 既存タグから選択
                    if (allTags.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '既存のタグから選択',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (allTags.length > 5)
                            TextButton.icon(
                              icon: Icon(
                                showAllTags ? Icons.expand_less : Icons.expand_more,
                                size: 18,
                              ),
                              label: Text(
                                showAllTags ? '閉じる' : 'もっと見る (${allTags.length}個)',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  showAllTags = !showAllTags;
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
                        children: (showAllTags ? allTags : allTags.take(5))
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
                      SizedBox(height: 16),
                    ],

                    // 新規タグ追加
                    Text('新しいタグを追加:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    TextField(
                      controller: tagController,
                      decoration: InputDecoration(
                        hintText: '例：仕事、勉強、趣味',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  // 全てのタグを展開
  void _expandAllTags(WidgetRef ref, List<MemoData> memos) {
    // 全てのタグを取得
    final tags = _getAllTags(memos);

    // 全て展開状態にする
    final newState = <String, bool>{};
    for (var tag in tags) {
      newState[tag] = true;
    }

    ref.read(tagExpansionStateProvider.notifier).state = newState;

    // バージョンをインクリメントして強制リビルド
    ref.read(tagExpansionVersionProvider.notifier).state++;
  }

  // 全てのタグを折りたたむ
  void _collapseAllTags(WidgetRef ref, List<MemoData> memos) {
    // 全てのタグを取得
    final tags = _getAllTags(memos);

    // 全て折りたたみ状態にする
    final newState = <String, bool>{};
    for (var tag in tags) {
      newState[tag] = false;
    }

    ref.read(tagExpansionStateProvider.notifier).state = newState;

    // バージョンをインクリメントして強制リビルド
    ref.read(tagExpansionVersionProvider.notifier).state++;
  }

  // 全てのタグを取得するヘルパー
  Set<String> _getAllTags(List<MemoData> memos) {
    final tags = <String>{};
    for (var memo in memos) {
      if (memo.tags.isEmpty) {
        tags.add('未分類');
      } else {
        tags.addAll(memo.tags);
      }
    }
    return tags;
  }

  // タグアイコン選択ダイアログ
  void _showIconSelectDialog(BuildContext context, WidgetRef ref, String tag) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$tag のアイコンを選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: availableTagIcons.length,
              itemBuilder: (context, index) {
                final entry = availableTagIcons.entries.elementAt(index);
                final iconKey = entry.key;
                final icon = entry.value;

                return InkWell(
                  onTap: () {
                    ref.read(tagIconProvider.notifier).setIcon(tag, iconKey);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 32, color: Colors.blue),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
}
