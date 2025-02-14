import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'subscription_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/advice_provider.dart';
import '../providers/subscription_status_notifier.dart';
import '../widgets/AIChat/user_bubble.dart';
import '../widgets/AIChat/AI_response.dart';
import '../widgets/AIChat/no_messages_placeholder.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String cardId;
  final String memoId;
  final String memoContent;
  final String title;
  final String description;
  final bool isFirstAdvice;

  AIChatScreen({
    required this.cardId,
    required this.memoId,
    required this.memoContent,
    required this.title,
    required this.description,
    this.isFirstAdvice = false,
  });

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isInitializing = false; // 初期化中かどうかのフラグ
  bool _isInitialized = false; // 初期化が完了したかどうかのフラグ
  bool _isPastLoading = false; // ロード中フラグ
  bool _hasMorePastData = true; // 更なるデータがあるかのフラグ
  bool _isSending = false; // 送信中かどうかのフラグ
  bool _showSubscriptionDialog = false; // ダイアログ表示フラグ
  /* _isShowedSubscriptionDialogは仮の処理であり、Dialog表示後に初期化が再度実行している挙動が理解できていないので調査をするのが理想（一度フラグ_showSubscriptionDialogが変更されていればtrue） */
  bool _isShowedSubscriptionDialog = false; // ダイアログが表示されたかどうかのフラグ
  List<QueryDocumentSnapshot> _pastMessages = []; // 過去のメッセージ
  DocumentSnapshot? _lastDocument; // 最後に取得したドキュメント
  int _pageSize = 20; // 1ページあたりの取得件数

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitializing && !_isInitialized && widget.isFirstAdvice) {
      _isInitializing = true; // 先にフラグを変更して二重実行を防ぐ

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initialize();
      });
    }
  }

  Future<void> _initialize() async {
    // _isInitializing = true; // フラグを直接操作
    try {
      final isSubscribed = ref.read(subscriptionStatusProvider);

      if (!isSubscribed) {
        if (!_isShowedSubscriptionDialog) {
          _isShowedSubscriptionDialog = true; // ダイアログを表示するフラグをセット
          _showSubscriptionDialog = true; // ダイアログを表示するフラグをセット
        }
        return; // 未課金なら初期化を中断
      }

      ref.read(adviceNotifierProvider.notifier).updateAdvice(widget.memoId, 'AIアドバイスを取得中...');
      setState(() {
        _isSending = true; // 送信中フラグを立てる
      });

      final advice = await _fetchAIAdvice(widget.memoContent);
      // _initialAdvice = advice;

      if (mounted) {
        ref.read(adviceNotifierProvider.notifier).updateAdvice(widget.memoId, advice);
      }
      // 🔹 成功した場合のみ、_isInitialized を true にする
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      //_hasError = true; // エラー時の処理
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false; // 初期化完了
          //_isInitialized = true;  // 初期化完了フラグを設定
          _isSending = false; // 送信中フラグを解除
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
    // ダイアログ表示（build メソッド内で）
    if (_showSubscriptionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionDialog = false; // 一度だけ表示するためにフラグをオフ
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("AIアドバイスを受けるには"),
            content: Text("AIアドバイスを受けるには、有料プランへの登録が必要です。"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(),
                    ),
                  );
                },
                child: Text("有料プランへ"),
              ),
            ],
          ),
        );
      });
    }

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: Text("AIチャット")),
        body: Center(child: CircularProgressIndicator()), // 初期化中の表示
      );
    }

    return GestureDetector(
      onTap: () {
        // 画面のどこかをタップしたらキーボードを閉じる
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.memoContent),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // チャット画面
            Expanded(
              child: _buildChatStream(), // チャットのリスト
            ),
            // 送信中のインジケーター
            if (_isSending)
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            // メッセージ入力
            _buildMessageInput(),
          ],
        ),
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
            // sending要対応
            final newMessages = newSnapshot.data ?? [];

            // 初期データ + 新しいデータを統合
            final allMessages = [
              ..._pastMessages, // 過去のメッセージ
              ...initialMessages, 
              ...newMessages
            ];

            // Firestore のドキュメント ID をキーにして重複を排除
            // 20件をinitialMessagesから取得しているため、元の件数が20以下だとnewMessagesと重複することへの対策
            final uniqueMessagesMap = { for (var msg in allMessages) msg.id : msg };
            // 重複を排除したリストに変換
            final combinedMessages = uniqueMessagesMap.values.toList();

            // `createdAt`で昇順に並べ替え
            combinedMessages.sort((a, b) {
              final dateA = a['createdAt'] as Timestamp;
              final dateB = b['createdAt'] as Timestamp;
              // return dateA.compareTo(dateB); // 昇順 (古い順)
              return dateB.compareTo(dateA); // 降順 (新しい順)
            });

            // 課金状態を確認
            final isSubscribed = ref.watch(subscriptionStatusProvider);

            // メッセージがなく、未課金の場合の専用画面
            if (combinedMessages.isEmpty && !isSubscribed) {
              return noMessagesPlaceholder(context);
            }

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
        bottom: isKeyboardVisible ? 8.0 : 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode, 
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
              onPressed: _isSending
                  ? null // 送信中は無効化
                  : () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        _handleMessageSubmission(text);
                      }
                    },
              child: _isSending
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text("送信"),
            ),
          ],
        ],
      ),
    );
  }
  
  
  Future<String> _fetchAIAdvice(
    String userMessage, {
    List<Map<String, dynamic>> pastMessages = const [],
  }) async {
    final functions = FirebaseFunctions.instance;

    // FirebaseAuth からユーザーIDを取得
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 空のリストでもJSON互換型を確保し、createdAtをISO 8601形式に変換
    final formattedPastMessages = pastMessages.map((msg) {
      final createdAt = msg['createdAt'];
      return {
        'content': msg['content'],
        'isAI': msg['isAI'],
        'createdAt': createdAt is DateTime
            ? createdAt.toIso8601String() // DateTimeをISO 8601形式に変換
            : createdAt, // すでに適切な形式ならそのまま
      };
    }).toList();

    try {
      final parameters = {
        'userMessage': userMessage,
        'pastMessages': formattedPastMessages,
        'userId': userId,
        'cardId': widget.cardId,
        'memoId': widget.memoId,
      };

      final result = await functions.httpsCallable('getAIAdvice').call(parameters);

      // 正常なレスポンスを返す
      //print('AIアドバイスの取得に成功: ${result.data}');
      return result.data;
    } catch (e) {
      print('Cloud Functionsの呼び出しエラー: $e');
      return 'AIアドバイスの取得に失敗しました。'; // エラーメッセージを返す
    }
  }

  Future<void> _handleMessageSubmission(String userMessage) async {
    //if (userMessage.isEmpty) return;
    if (userMessage.isEmpty || _isSending) return;

    setState(() {
      _isSending = true; // 送信中フラグを立てる
    });

    // 課金ユーザでないならDialogを表示
    final isSubscribed = ref.watch(subscriptionStatusProvider);
    if (!isSubscribed) {
      // キーボードを閉じる
      _messageFocusNode.unfocus();
      // 有料プランのダイアログを表示
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("AIアドバイスを受けるには"),
            content: Text("AIアドバイスを受けるには、有料プランへの登録が必要です。"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(),
                    ),
                  );
                },
                child: Text("有料プランへ"),
              ),
            ],
          );
        },
      );

      setState(() {
        _isSending = false; // 送信中フラグを解除
      });
      return;
    }

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
      // Firestoreから過去20件のやり取りを取得
      final pastMessagesSnapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final pastMessages = pastMessagesSnapshot.docs
        .map((doc) => {
              'content': doc['content'],
              'isAI': doc['isAI'],
              'createdAt': (doc['createdAt'] as Timestamp).toDate(),
            })
        .toList()
        .reversed
        .toList(); // 時系列順に逆転

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
      final aiResponse = await _fetchAIAdvice(userMessage, pastMessages: pastMessages);

      ref.read(adviceNotifierProvider.notifier).updateAdvice(widget.memoId, aiResponse);
      // FirestoreにAIのレスポンスを保存
      //await _saveAdviceToFirestore(widget.cardId, widget.memoId, aiResponse);
    } catch (e) {
      // エラー処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false; // 送信中フラグを解除
        });
      }
    }
  }
}
