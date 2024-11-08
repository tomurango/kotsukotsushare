import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/card_memos_provider.dart';
import '../widgets/reflection_bottom_sheet.dart';
import '../models/memo_data.dart';
import 'package:intl/intl.dart';

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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // 周囲に16ピクセルのパディングを追加
            child: Text(
              description,
              style: TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            child: memosAsyncValue.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return Center(child: Text('メモはありません。'));
                }


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
