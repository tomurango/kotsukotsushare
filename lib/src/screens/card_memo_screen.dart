import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/card_memos_provider.dart';
import '../widgets/reflection_bottom_sheet.dart';
import '../models/memo_data.dart';
import 'package:intl/intl.dart';
import 'edit_card_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardMemoScreen extends ConsumerWidget {
  final String cardId;
  final String title;
  final String description;

  CardMemoScreen({
    required this.cardId,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsyncValue = ref.watch(memosProvider(cardId)); // メモデータを取得

    // 日付のフォーマットを設定
    String formatDate(DateTime date) {
      final DateFormat formatter = DateFormat('yyyy/MM/dd'); // 日付だけを表示する形式
      return formatter.format(date);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground, // テーマに基づいた色
          ),
        ),
        actions: [
          // 編集ボタン
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCardScreen(
                    cardId: cardId,
                    initialTitle: title,
                    initialDescription: description,
                  ),
                ),
              );
            },
            tooltip: '編集する',
          ),
          // 削除ボタン
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // 削除確認ダイアログを表示
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('カードの削除'),
                    content: Text(
                      'このカードを削除すると、カードに追加されたメモもすべて削除されます。\n本当に削除してもよろしいですか？',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // キャンセル
                        child: Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true), // 削除を確定
                        child: Text('削除', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  );
                },
              );

              // ユーザーが削除を確定した場合
              if (shouldDelete == true) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('cards')
                      .doc(cardId)
                      .delete();

                  // 成功したら画面を閉じる
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('カードを削除しました')),
                  );
                } catch (e) {
                  // エラーハンドリング
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            tooltip: '削除する',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // 周囲に16ピクセルのパディングを追加
            child: Text(
              description,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onBackground, // テーマに基づいた色
              ),
            ),
          ),
          Divider(),
          Expanded(
            child: memosAsyncValue.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return Center(child: Text('メモはありません。'));
                }

                return ListView.builder(
                  itemCount: memos.length * 2,
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      return Divider();
                    }

                    final memoIndex = index ~/ 2;
                    final memo = memos[memoIndex];

                    // memo.typeに基づいて表示内容を分ける
                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (memo.type == 'reflection') ...[
                            Text("何があったか: ${memo.content}"),
                            SizedBox(height: 4),
                            Text("どう感じたか: ${memo.feeling}"),
                            SizedBox(height: 4),
                            Text("面白い真実は何か: ${memo.truth}"),
                          ] else
                            Text(memo.content),
                        ],
                      ),
                      subtitle: Text(
                        "${formatDate(memo.createdAt)} - ${memo.isPublic ? 'Public' : 'Private'}",
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editMemo(context, memo);
                              break;
                            case 'delete':
                              _deleteMemo(context, memo);
                              break;
                            case 'togglePublic':
                              _togglePublicFlag(context, memo);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(value: 'edit', child: Text('編集')),
                          PopupMenuItem(value: 'delete', child: Text('削除')),
                          PopupMenuItem(
                            value: 'togglePublic',
                            child: Text(memo.isPublic ? '非公開にする' : '公開にする'),
                          ),
                        ],
                      ),
                    );
                  },
                );


                /*
                return ListView.builder(
                  itemCount: memos.length * 2 ,
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      return Divider();
                    }
                    final memoIndex = index ~/ 2;
                    final memo = memos[memoIndex];

                    // memo.typeに基づいて表示内容を分ける
                    if (memo.type == 'reflection') {
                      // reflectionの場合、feelingとtruthも表示
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("何があったか: ${memo.content}"), // "内容"
                            SizedBox(height: 4),
                            Text("どう感じたか: ${memo.feeling}"), // "どう感じたか"
                            SizedBox(height: 4),
                            Text("面白い真実は何か: ${memo.truth}"), // "面白い真実は何か"
                          ],
                        ),
                        subtitle: Text(
                          "${formatDate(memo.createdAt)} - ${memo.isPublic ? 'Public' : 'Private'}",
                        ),
                      );
                    } else {
                      // memoの場合、contentのみ表示
                      return ListTile(
                        title: Text(memo.content),
                        subtitle: Text(
                          "${formatDate(memo.createdAt)} - ${memo.isPublic ? 'Public' : 'Private'}",
                        ),
                      );
                    }
                  },
                );
                */
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // FABを押したときにボトムシートを表示
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // 高さに応じてスクロール可能に
            builder: (context) {
              // Fabを押したときに表示するボトムシートは空白のメモデータを渡す
              return ReflectionBottomSheet(memo: MemoData.empty(), cardId: cardId);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

void _editMemo(BuildContext context, MemoData memo) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return ReflectionBottomSheet(memo: memo, cardId: memo.cardId);
    },
  );
}

void _deleteMemo(BuildContext context, MemoData memo) async {
  // 削除確認ダイアログ
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('メモの削除'),
        content: Text(
          'このメモを削除しますか？',
          style: TextStyle(fontSize: 16),
        ),
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

  // ユーザーが「削除」を選択した場合のみ実行
  if (shouldDelete == true) {
    try {
      // Firestoreからメモを削除
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('cards')
          .doc(memo.cardId)
          .collection('memos')
          .doc(memo.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('メモを削除しました'),
            backgroundColor: Colors.green, // 成功時の色
          ),
        );
      }
    } catch (e) {
      print('削除エラー: $e'); // エラーログをコンソールに表示

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red, // 失敗時の色
          ),
        );
      }
    }
  }
}

void _togglePublicFlag(BuildContext context, MemoData memo) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('cards')
        .doc(memo.cardId)
        .collection('memos')
        .doc(memo.id)
        .update({'isPublic': !memo.isPublic});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(memo.isPublic ? '非公開にしました' : '公開にしました'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('更新に失敗しました: $e')),
    );
  }
}
