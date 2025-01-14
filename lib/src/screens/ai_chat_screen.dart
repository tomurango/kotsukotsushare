import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/advice_provider.dart';
import '../widgets/AIChat/user_bubble.dart';
import '../widgets/AIChat/AI_response.dart';

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
  bool _isPastLoading = false; // ロード中フラグ
  bool _hasMorePastData = true; // 更なるデータがあるかのフラグ
  List<QueryDocumentSnapshot> _pastMessages = []; // 過去のメッセージ
  DocumentSnapshot? _lastDocument; // 最後に取得したドキュメント
  int _pageSize = 20; // 1ページあたりの取得件数

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
        title: Text(widget.memoContent),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
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

  // 初期データを取得するクエリ
  Future<List<QueryDocumentSnapshot>> _fetchInitialData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .doc(widget.cardId)
        .collection('memos')
        .doc(widget.memoId)
        .collection('advices')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize) // 初期データ数を制限
        .get();

    // ページサイズより取得件数が少ない場合、さらに取得するデータがないと判断
    if (querySnapshot.docs.length < _pageSize) {
      _hasMorePastData = false;
    }

    return querySnapshot.docs;
  }

  // リアルタイムで新しいデータを監視
  Stream<List<QueryDocumentSnapshot>> _watchNewData(Timestamp lastTimestamp) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .doc(widget.cardId)
        .collection('memos')
        .doc(widget.memoId)
        .collection('advices')
        .orderBy('createdAt', descending: false)
        .startAfter([lastTimestamp]) // 最初のデータ以降を取得
        .snapshots()
        .map((snapshot) => snapshot.docs); // Stream に変換
  }

  // 過去のデータを取得
  Future<void> _fetchMorePastData() async {
    if (_isPastLoading || _lastDocument == null || !_hasMorePastData) return; // ロード中・データがない・さらに読み込むデータがない場合は終了

    setState(() {
      _isPastLoading = true;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .doc(widget.cardId)
        .collection('memos')
        .doc(widget.memoId)
        .collection('advices')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDocument!) // 現在の最後のドキュメントから開始
        .limit(_pageSize) // 取得件数を制限
        .get();

    setState(() {
      if (querySnapshot.docs.isNotEmpty) {
        _pastMessages.addAll(querySnapshot.docs); // 過去のメッセージをリストに追加
        _lastDocument = querySnapshot.docs.last; // 最後のドキュメントを更新
      }

      // ページサイズより取得件数が少ない場合、さらに取得するデータがないと判断
      if (querySnapshot.docs.length < _pageSize) {
        _hasMorePastData = false;
      }

      _isPastLoading = false;
    });
  }


  // UI内で使用
  Widget _buildChatStream() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchInitialData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final initialMessages = snapshot.data!;
        final lastTimestamp = Timestamp.now();

        return StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _watchNewData(lastTimestamp),
          builder: (context, newSnapshot) {
            final newMessages = newSnapshot.data ?? [];

            // 初期データ + 新しいデータを統合
            final combinedMessages = [
              ..._pastMessages, // 過去のメッセージ
              ...initialMessages, 
              ...newMessages
            ];

            // `createdAt`で昇順に並べ替え
            combinedMessages.sort((a, b) {
              final dateA = a['createdAt'] as Timestamp;
              final dateB = b['createdAt'] as Timestamp;
              // return dateA.compareTo(dateB); // 昇順 (古い順)
              return dateB.compareTo(dateA); // 降順 (新しい順)
            });

            // リストの中で一番古いドキュメントを更新
            if (combinedMessages.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _lastDocument = combinedMessages.last;
                });
              });
            }

            return ListView.builder(
              reverse: true, // 最新のメッセージを下に表示
              itemCount: combinedMessages.length + (_hasMorePastData ? 1 : 0),
              itemBuilder: (context, index) {
                if (_hasMorePastData && index == combinedMessages.length) {
                  // 過去のメッセージを取得するボタン
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.center, // ボタンを中央に配置
                      child: ElevatedButton(
                        onPressed: _isPastLoading ? null : _fetchMorePastData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero, // 最小サイズを無効化
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // タップ領域を縮小
                        ),
                        child: _isPastLoading
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "過去のメッセージを表示",
                                style: TextStyle(fontSize: 14),
                              ),
                      ),
                    ),
                  );
                }

                final message = combinedMessages[index];
                final isAI = message['isAI'] ?? false;
                final content = message['content'] ?? '';
                final createdAt = message['createdAt'] as Timestamp;

                // Timestamp を DateTime に変換し、フォーマット
                final dateTime = createdAt.toDate();
                final formattedDate =
                    "${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}";

                if (isAI) {
                  return AIResponse(
                    message: content,
                    // time: formattedDate,
                  );
                } else {
                  return UserBubble(
                    message: content,
                    time: formattedDate,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 32.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Chokushiiに相談",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32.0), // 角を丸くする
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0), // フォーカス時も角を丸く
                  borderSide: BorderSide(color: Colors.teal, width: 2.0),
                ),
                //border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                // 文字入力時に状態を更新
                setState(() {});
              },
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _handleMessageSubmission(text);
                }
              },
            ),
          ),
          if (_messageController.text.trim().isNotEmpty) ...[
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
