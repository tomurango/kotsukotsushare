import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          // ログイン状態に応じて画面を切り替え
          if (user == null) {
            return LoginScreen(); // 未ログイン
          } else {
            return MainScreen(); // ログイン済み
          }
        } else {
          return CircularProgressIndicator(); // 読み込み中
        }
      },
    );
  }
}
