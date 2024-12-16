import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditCardScreen extends StatefulWidget {
  final String cardId; // Firebase上のカードID
  final String initialTitle;
  final String initialDescription;

  const EditCardScreen({
    Key? key,
    required this.cardId,
    required this.initialTitle,
    required this.initialDescription,
  }) : super(key: key);

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // 初期値をセット
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateCard() async {
    try {
        final user = FirebaseAuth.instance.currentUser; // 現在のユーザー情報を取得

        if (user != null) {
        // Firestoreの特定のカードIDに対してデータを上書き
        await FirebaseFirestore.instance
            .collection('users') // usersコレクション
            .doc(user.uid) // 現在のユーザーID
            .collection('cards') // cardsサブコレクション
            .doc(widget.cardId) // 特定のカードID
            .update({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'updatedAt': Timestamp.now(), // 更新時刻を記録
        });

        // 保存後に前の画面に戻る
        Navigator.pop(context);

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('カードが更新されました')),
        );
        }
    } catch (e) {
        // エラー処理
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カードを編集'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力欄
            const Text('タイトル', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '新しいタイトルを入力してください',
              ),
            ),
            const SizedBox(height: 16),

            // 詳細入力欄
            const Text('詳細', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '新しい詳細を入力してください',
              ),
            ),
            const SizedBox(height: 24),

            // 更新ボタン
            Center(
              child: ElevatedButton(
                onPressed: _updateCard,
                child: const Text('保存する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
