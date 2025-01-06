import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/advice_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String cardId;
  final String memoId;
  final String memoContent;
  final String title;
  final String description;
  final bool firstAdvice;

  AIChatScreen({
    required this.cardId,
    required this.memoId,
    required this.memoContent,
    required this.title,
    required this.description,
    this.firstAdvice = false,
  });

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isInitializing = false; // 初期化中かどうかのフラグ

  @override
  void initState() {
    super.initState();
    if (widget.firstAdvice) {
      _initialize(); // 初回アドバイスの取得を実行
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true; // 初期化中
    });

    try {
      // 初回アドバイスの取得
      final advice = await _fetchAIAdvice(widget.memoContent);
      if (mounted) {
        await _saveAdviceToFirestore(widget.cardId, widget.memoId, advice);

        // Riverpodの状態更新
        ref
            .read(adviceNotifierProvider.notifier)
            .updateAdvice(widget.memoId, advice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("アドバイスの取得に失敗しました: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false; // 初期化完了
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: Text("AIチャット")),
        body: Center(child: CircularProgressIndicator()), // 初期化中の表示
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("AIチャット"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // メモ表示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "タイトル: ${widget.title}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text("説明: ${widget.description}"),
                Divider(),
                Text("メモ: ${widget.memoContent}"),
              ],
            ),
          ),
          Divider(),
          // チャット画面
          Expanded(
            child: _buildChatStream(), // チャットのリスト
          ),
          // メッセージ入力
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatStream() {
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .doc(widget.cardId)
        .collection('memos')
        .doc(widget.memoId)
        .collection('advices')
        .orderBy('createdAt', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isAI = message['isAI'] ?? false;

            return Align(
              alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAI ? Colors.teal.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message['content']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "メッセージを入力してください",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _handleMessageSubmission(text);
                }
              },
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final text = _messageController.text.trim();
              if (text.isNotEmpty) {
                _handleMessageSubmission(text);
              }
            },
            child: Text("送信"),
          ),
        ],
      ),
    );
  }
  
  Future<String> _fetchAIAdvice(String content) async {
    await Future.delayed(Duration(seconds: 2)); // ダミー遅延

    // contentの長さを確認して範囲内の部分文字列を取得
    final previewLength = content.length < 10 ? content.length : 10;
    final preview = content.substring(0, previewLength);

    return "アドバイス: $preview...に注目しましょう。";
  }

  Future<void> _saveAdviceToFirestore(
      String cardId, String memoId, String advice) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .collection('memos')
        .doc(memoId)
        .collection('advices')
        .add({
      'content': advice,
      'isAI': true,
      'createdAt': Timestamp.now(),
    });

    // Riverpodの状態を更新
    ref.read(adviceNotifierProvider.notifier).updateAdvice(memoId, advice);
  }

  Future<void> _handleMessageSubmission(String userMessage) async {
    if (userMessage.isEmpty) return;

    // Firestoreコレクションの参照を取得
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .doc(widget.cardId)
        .collection('memos')
        .doc(widget.memoId)
        .collection('advices');

    try {
        // ユーザーのメッセージをFirestoreに保存
        await collection.add({
        'content': userMessage,
        'isAI': false,
        'createdAt': Timestamp.now(),
        });

        // メッセージ送信後に入力フィールドをクリア（画面がまだ存在している場合のみ実行）
        if (mounted) {
        _messageController.clear();
        }

        // AIのレスポンスを生成
        final aiResponse = await _fetchAIAdvice(userMessage);

        // FirestoreにAIのレスポンスを保存
        await _saveAdviceToFirestore(widget.cardId, widget.memoId, aiResponse);
    } catch (e) {
        // エラー処理
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
        );
        }
    }
  }
}
