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
                /* 一時的に時刻は非表示
                subtitle: Text(
                  "${formatDate(memo.createdAt)}",
                ),*/
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
                /* 一時的に時刻は非表示
                subtitle: Text(
                  "${formatDate(memo.createdAt)}",
                ),*/
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
            ListTile(
              leading: Icon(Icons.flag),
              title: Text('報告する'),
              onTap: () {
                Navigator.pop(context); // ボトムシートを閉じる
                _reportContent(context, memoUserId, type, content, feeling, truth);
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

// 報告する処理
void _reportContent(BuildContext context, String memoUserId, String type, String content, String feeling, String truth) {
  final TextEditingController reportReasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("報告内容の確認"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("この投稿を報告する理由を入力してください。"),
            SizedBox(height: 8),
            TextField(
              controller: reportReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '報告理由',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text("キャンセル"),
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
          ),
          TextButton(
            child: Text("報告する"),
            onPressed: () {
              final reportReason = reportReasonController.text;
              
              // Firebaseに報告データを保存する処理
              FirebaseFirestore.instance.collection('reports').add({
                'reportedUserId': memoUserId,
                'type': type,
                'content': content,
                'feeling': feeling,
                'truth': truth,
                'reportReason': reportReason, // 入力された報告理由を追加
                'reportedAt': Timestamp.now(),
                'reportingUserId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown', // 現在のユーザーID
              }).then((value) {
                // ダイアログが閉じる前にスナックバーを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('報告が完了しました。'))
                );
                Navigator.of(context).pop(); // ダイアログを閉じる
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('報告に失敗しました。再度お試しください。'))
                );
              });
            },
          ),
        ],
      );
    },
  );
}
