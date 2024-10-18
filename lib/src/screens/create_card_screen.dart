import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCardScreen extends HookWidget {
  final String title;
  final String category; // カテゴリーを渡すためのプロパティ
  CreateCardScreen({required this.title, required this.category});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final formKey = GlobalKey<FormState>();

    void saveCard() async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && formKey.currentState!.validate()) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .add({
          'title': titleController.text,
          'description': descriptionController.text,
          'category': category,
          'createdAt': Timestamp.now(),
        });

        // 保存後に前の画面に戻る
        Navigator.of(context).pop();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: title == 'Important' ? '大切なこと' : '大切じゃないこと',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '大切なことを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: '説明'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveCard,
                child: Text('作成する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
