import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/card_memos_provider.dart';

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
    final memoController = TextEditingController();
    final isPublic = ref.watch(memoIsPublicProvider); // 公開フラグの状態をRiverpodから取得
    final user = ref.watch(userProvider); // 現在のユーザーをRiverpodのProviderから取得
    final memosAsyncValue = ref.watch(memosProvider(cardId)); // メモデータを取得

    void _addMemo() async {
      if (user != null && memoController.text.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid) // 現在のユーザーのUIDを使用
            .collection('cards')
            .doc(cardId)
            .collection('memos')
            .add({
          'content': memoController.text,
          'createdAt': Timestamp.now(),
          'isPublic': isPublic,
        });
        memoController.clear();
        ref.read(memoIsPublicProvider.notifier).state = true; // フラグをリセット
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Memos for Card'),
      ),
      body: Column(
        children: [
          Text(title),
          Text(description),
          Expanded(
            child: memosAsyncValue.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return Center(child: Text('No memos yet.'));
                }
                return ListView.builder(
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    return ListTile(
                      title: Text(memo.content),
                      subtitle: Text(
                        "${memo.createdAt} - ${memo.isPublic ? 'Public' : 'Private'}",
                      ),
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: memoController,
                        decoration: InputDecoration(
                          labelText: 'Enter memo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPublic ? Icons.public : Icons.lock,
                        color: isPublic ? Colors.green : Colors.red,
                      ),
                      onPressed: () {
                        showMenu(
                          context: context,
                          position: RelativeRect.fill,
                          items: [
                            PopupMenuItem(
                              value: true,
                              child: ListTile(
                                leading: Icon(Icons.public),
                                title: Text('Public'),
                              ),
                            ),
                            PopupMenuItem(
                              value: false,
                              child: ListTile(
                                leading: Icon(Icons.lock),
                                title: Text('Private'),
                              ),
                            ),
                          ],
                        ).then((value) {
                          if (value != null) {
                            ref.read(memoIsPublicProvider.notifier).state = value;
                          }
                        });
                      },
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _addMemo,
                      child: Text('Add'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

