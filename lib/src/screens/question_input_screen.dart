import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/question_provider.dart';

// ボタンの有効 / 無効状態を管理するプロバイダー
final questionTextProvider = StateProvider<String>((ref) => "");

class QuestionInputScreen extends ConsumerStatefulWidget {
  @override
  _QuestionInputScreenState createState() => _QuestionInputScreenState();
}

class _QuestionInputScreenState extends ConsumerState<QuestionInputScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() {
      // 入力が変更されたら `questionTextProvider` を更新
      ref.read(questionTextProvider.notifier).state = _questionController.text;
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submitQuestion() async {
    if (_questionController.text.isEmpty) return;

    // 確認ダイアログ
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    Map<String, dynamic>? response = await addQuestion(_questionController.text);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('質問を投稿しました！')),
      );
      _questionController.clear();
      ref.read(questionTextProvider.notifier).state = ""; // 入力をクリア
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('質問の投稿に失敗しました。')),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('質問投稿'),
        content: Text('この質問を投稿しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('投稿する'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isButtonActive = ref.watch(questionTextProvider).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "質問を入力",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "質問を入力してください",
            ),
            maxLines: 5,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 戻るボタン
              ElevatedButton(
                onPressed: () {
                  ref.read(selectedQuestionScreenProvider.notifier).state = 0;
                },
                child: Text("戻る"),
              ),
              // 質問投稿ボタン (入力があるときのみ有効)
              ElevatedButton(
                onPressed: isButtonActive ? _submitQuestion : null, // 入力があるときだけ有効
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonActive ? Color(0xFF008080) : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text("質問を投稿"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> addQuestion(String question) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("ログインしていません");
        return null;
      }

      final functions = FirebaseFunctions.instance;
      final HttpsCallable callable = functions.httpsCallable('addQuestion');

      final response = await callable.call({
        'question': question,
      });

      return response.data;
    } catch (e) {
      print("質問投稿エラー: $e");
      return null;
    }
  }
}
