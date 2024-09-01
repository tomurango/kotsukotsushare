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
        title: Text('Create $title Card'),
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
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveCard,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
