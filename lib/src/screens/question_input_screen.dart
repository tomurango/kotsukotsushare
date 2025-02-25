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

    Map<String, dynamic>? response = await addQuestion(_questionController.text);

    if (response != null) {
      String status = response['status'];
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
            maxLines: 3,
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
                  backgroundColor: isButtonActive ? Colors.blue : Colors.grey,
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

      // print("ログイン中: ${currentUser.uid}");

      // 🔥 FirebaseAuth のトークンを取得
      String? idToken = await currentUser.getIdToken();

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
