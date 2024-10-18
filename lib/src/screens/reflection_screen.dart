import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/public_memos_provider.dart';
import 'package:intl/intl.dart';

class ReflectionScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  ReflectionScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のユーザーを取得
    final user = ref.watch(userProvider);

    if (user == null) {
      return Center(child: Text('ログインしているユーザーがいません。'));
    }

    // 全ての公開メモを取得
    final memosAsyncValue = ref.watch(publicMemosProvider);

    // 日付のフォーマットを設定
    String formatDate(DateTime date) {
      final DateFormat formatter = DateFormat('yyyy/MM/dd'); // 日付だけを表示する形式
      return formatter.format(date);
    }

    return memosAsyncValue.when(
      data: (memos) {
        if (memos.isEmpty) {
          return Center(child: Text('公開されているメモはありません。'));
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
                  "${formatDate(memo.createdAt)}",
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    _showOptionsBottomSheet(context, memo.userId, memo.type, memo.content, memo.feeling ?? '', memo.truth ?? '');
                  },
                ),
              );
            } else {
              // memoの場合、contentのみ表示
              return ListTile(
                title: Text(memo.content),
                subtitle: Text(
                  "${formatDate(memo.createdAt)}",
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    _showOptionsBottomSheet(context, memo.userId, memo.type, memo.content, memo.feeling ?? '', memo.truth ?? '');
                  },
                ),
              );
            }
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
    );
  }
}

// ボトムシートを表示する関数
void _showOptionsBottomSheet(BuildContext context, String memoUserId, String type, String content, String feeling, String truth) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.block),
              title: Text('ユーザをブロックする'),
              onTap: () {
                _blockUser(context, memoUserId, type, content, feeling, truth);
                Navigator.pop(context); // ボトムシートを閉じる
              },
            ),
          ],
        ),
      );
    },
  );
}

// ユーザをブロックする処理
void _blockUser(BuildContext context, String memoUserId, String type , String content, String feeling, String truth) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // ブロックするユーザーのIDとメモの内容を保存
  if (currentUserId != null) {
    FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('blockedUsers')
      .doc(memoUserId)
      .set({
        'blockedAt': Timestamp.now(),
        'type': type,
        'content': content,
        'feeling': feeling,
        'truth': truth,
      });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ユーザをブロックしました')),
    );
  }
}
