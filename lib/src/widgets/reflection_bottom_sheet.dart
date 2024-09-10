import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReflectionBottomSheet extends StatelessWidget {
  final MemoData memo;

  ReflectionBottomSheet({required this.memo});

  @override
  Widget build(BuildContext context) {
    final reflectionController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reflect on this memo:'),
          SizedBox(height: 8),
          Text(memo.content, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          TextField(
            controller: reflectionController,
            decoration: InputDecoration(
              labelText: 'Enter your reflection',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // ユーザーごとのreflectionsサブコレクションにデータを保存
              final reflection = reflectionController.text;
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('reflections') // users -> reflectionsに保存
                  .add({
                'memoId': memo.id,
                'memoContent': memo.content, // メモの内容を記録
                'reflection': reflection,
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(context); // ボトムシートを閉じる
            },
            child: Text('Save Reflection'),
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
