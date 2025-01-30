import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIResponse extends StatelessWidget {
  final String message;

  const AIResponse({
    required this.message,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 子の高さに基づいて縮小
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AIアイコン


        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.teal,
                child: const Icon(Icons.smart_toy, color: Colors.white),
              ),
            ],
          ),
        ),

        // 全画面の回答表示
        Flexible(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView( // スクロール可能にする
              // 回答メッセージはマークダウン対応
              child: MarkdownBody(
                data: message, // マークダウンとして解釈
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16), // 通常のテキスト
                  strong: const TextStyle(fontWeight: FontWeight.bold), // **太字**
                  em: const TextStyle(fontStyle: FontStyle.italic), // *斜体*
                  code: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.grey), // `コード`
                ),
              ),
              /*
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              */
            ),
          ),
        ),
        // 余白
        const SizedBox(height: 16),
      ],
    );
  }
}
