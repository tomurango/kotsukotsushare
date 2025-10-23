import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/local_data_provider.dart';

class CreateCardScreen extends HookConsumerWidget {
  final String title;
  final String category;

  CreateCardScreen({required this.title, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();

    void saveCard() async {
      final user = FirebaseAuth.instance.currentUser;
      final useLocal = ref.read(useLocalDataProvider);
      final localDataService = ref.read(localDataServiceProvider);

      // バリデーション
      if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('すべてのフィールドを入力してください。')),
        );
        return;
      }

      if (user != null) {
        try {
          final cardId = FirebaseFirestore.instance.collection('temp').doc().id;
          final card = CardData(
            id: cardId,
            title: titleController.text,
            description: descriptionController.text,
            category: category,
          );

          if (useLocal) {
            // ローカルデータを使用する場合
            await localDataService.addCard(card);
          } else {
            // Firestoreを使用する場合
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cards')
                .doc(cardId)
                .set({
              'title': titleController.text,
              'description': descriptionController.text,
              'category': category,
              'createdAt': Timestamp.now(),
            });
          }

          titleController.clear();
          descriptionController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('カードを作成しました！')),
          );

          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title == 'Important'
              ? '大切なことカード作成'
              : '大切じゃないことカード作成',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == 'Important'
                  ? 'ここに大切なことを記録しましょう。'
                  : 'ここに大切じゃないことを記録しましょう。',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: title == 'Important' ? '大切なこと' : '大切じゃないこと',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: '説明'),
            ),
            SizedBox(height: 20),
            Text('※ここで入力した内容は他のユーザーに公開されないので、安心して記録してください。'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveCard,
              child: Text('作成する'),
            ),
          ],
        ),
      ),
    );
  }
}
