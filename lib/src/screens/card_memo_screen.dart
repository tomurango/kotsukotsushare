import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardMemoScreen extends HookWidget {
  final String cardId; // カードIDを受け取る
  final String title;
  final String description;

  CardMemoScreen({required this.cardId, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final memoController = useTextEditingController();
    // memoの公開フラグをSwitchで管理するためのローカル状態
    final isPublic = useState(false);

    Stream<List<MemoData>> _getMemos() {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cards')
          .doc(cardId)
          .collection('memos')
          .orderBy('createdAt', descending: true) // 新しい順にソート
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                return MemoData(
                  id: doc.id,
                  content: data['content'] ?? '',
                  createdAt: (data['createdAt'] as Timestamp).toDate(),
                  isPublic: data['isPublic'] ?? false,
                );
              }).toList());
    }

    void _addMemo() async {
      if (memoController.text.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('cards')
            .doc(cardId)
            .collection('memos')
            .add({
          'content': memoController.text,
          'createdAt': Timestamp.now(),
          'isPublic': isPublic.value,
        });
        memoController.clear();
        isPublic.value = true;
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
            child: StreamBuilder<List<MemoData>>(
              stream: _getMemos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No memos yet.'));
                }

                final memos = snapshot.data!;

                return ListView.builder(
                  reverse: false,
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
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: Icon(
                            isPublic.value ? Icons.public : Icons.lock,
                            color: isPublic.value ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            final RenderBox button = context.findRenderObject() as RenderBox;
                            final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                            final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                position.dx + button.size.width,
                                position.dy,
                                position.dx + button.size.width,
                                overlay.size.height - position.dy - button.size.height,
                              ),
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
                                isPublic.value = value;
                              }
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(width: 8),
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

class MemoData {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isPublic;

  MemoData({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isPublic,
  });
}
