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
        SnackBar(content: Text('質問を事務局に送信しました。匿名で公開されます。')),
      );
      _questionController.clear();
      ref.read(questionTextProvider.notifier).state = ""; // 入力をクリア
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('質問の送信に失敗しました。')),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('質問を送信'),
        content: Text('この質問を事務局に送信しますか？\n\nあなたの質問は匿名で他のユーザーに公開されます。個人情報は一切表示されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('送信する'),
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
            "事務局に質問を送る",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "質問は匿名で公開されます。あなたの個人情報は表示されません。",
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "悩みや疑問を自由に書いてください",
              helperText: "例：仕事のモチベーションが上がらない、人間関係で困っている など",
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
              // 質問送信ボタン (入力があるときのみ有効)
              ElevatedButton(
                onPressed: isButtonActive ? _submitQuestion : null, // 入力があるときだけ有効
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonActive ? Color(0xFF008080) : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text("事務局に送る"),
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
