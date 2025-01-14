import 'package:flutter/material.dart';

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
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        // 余白
        const SizedBox(height: 16),
        // 水平線
        const Divider(height: 1, thickness: 1),
        // 余白
        const SizedBox(height: 16),
      ],
    );
  }
}
