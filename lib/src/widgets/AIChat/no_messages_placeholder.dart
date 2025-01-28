import 'package:flutter/material.dart';
import '../../screens/subscription_screen.dart'; // SubscriptionScreenのインポート

Widget noMessagesPlaceholder(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "まだメッセージがありません",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionScreen()),
            );
          },
          child: Text("有料プランに登録"),
        ),
      ],
    ),
  );
}
