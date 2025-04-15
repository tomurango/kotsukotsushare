// lib/screens/blocked_questions_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BlockedQuestionsScreen extends StatefulWidget {
  const BlockedQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<BlockedQuestionsScreen> createState() => _BlockedQuestionsScreenState();
}

class _BlockedQuestionsScreenState extends State<BlockedQuestionsScreen> {
  late Future<List<Map<String, dynamic>>> _blockedQuestions;

  @override
  void initState() {
    super.initState();
    _blockedQuestions = _fetchBlockedQuestions();
  }

  Future<List<Map<String, dynamic>>> _fetchBlockedQuestions() async {
    final callable = FirebaseFunctions.instance.httpsCallable('getBlockedQuestions');
    final result = await callable.call();
    final List<dynamic> data = result.data["questions"];
    return data.map((e) => Map<String, dynamic>.from(e)).toList(); // 型を明示的に変換
  }

  Future<void> _unblockByQuestionId(String questionId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable("unblockUserByQuestionId");
      await callable.call({
        "questionId": questionId,
      });

      setState(() {
        _blockedQuestions = _fetchBlockedQuestions();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ブロックを解除しました")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("解除に失敗しました: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ブロック済み質問")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _blockedQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("ブロック中の質問はありません"));
          }

          final blockedList = snapshot.data!;
          return ListView.builder(
            itemCount: blockedList.length,
            itemBuilder: (context, index) {
              final item = blockedList[index];
              final questionId = item["questionId"] ?? "";
              final text = item["text"] ?? "";
              final createdAt = item["createdAt"];
              final formattedDate = item["createdAt"] is String
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item["createdAt"]))
                : "不明";

              return ListTile(
                title: Text(text),
                subtitle: Text("ブロックをした日: $formattedDate"),
                trailing: TextButton(
                  onPressed: () => _unblockByQuestionId(questionId),
                  child: const Text("解除", style: TextStyle(color: Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
