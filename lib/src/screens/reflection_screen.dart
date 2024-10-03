import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/public_memos_provider.dart';

class ReflectionScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  ReflectionScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のユーザーを取得
    final user = ref.watch(userProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('メモ一覧')),
        body: Center(child: Text('ログインしているユーザーがいません。')),
      );
    }

    // 全ての公開メモを取得
    final memosAsyncValue = ref.watch(publicMemosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('メモ一覧'),
      ),
      body: memosAsyncValue.when(
        data: (memos) {
          if (memos.isEmpty) {
            return Center(child: Text('公開されているメモはありません。'));
          }
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (memo.type == 'reflection') ...[
                        Text(
                          "何があったか",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(memo.content),
                        SizedBox(height: 12), // 適度なスペース
                        
                        Text(
                          "どう感じたか",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(memo.feeling ?? ''),
                        SizedBox(height: 12),

                        Text(
                          "面白い真実は何か",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(memo.truth ?? ''),
                        SizedBox(height: 12),
                      ] else ...[
                        SizedBox(height: 4),
                        Text(memo.content),
                        SizedBox(height: 12),
                      ],

                      // 日付や公開・非公開情報を表示
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "作成日: ${memo.createdAt}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            memo.isPublic ? "公開" : "非公開",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          // オプションボタン
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              _showOptionsBottomSheet(context, memo.userId, memo.type, memo.content, memo.feeling ?? '', memo.truth ?? '');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
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
