import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Googleサインイン
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // ユーザーがキャンセルした場合はnullを返す
      if (googleUser == null) return null;

      // 認証情報の取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebaseの認証クレデンシャルを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // FirebaseでGoogleログイン
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ画像を表示
            Image.asset(
              'assets/images/chokushii_logo_1024.png', // ロゴ画像のパス
              height: 150, // ロゴの高さを設定
            ),
            SizedBox(height: 40), // ロゴとボタンの間にスペースを入れる

            // SignInButtonライブラリを使用してGoogleログインボタンを作成
            SignInButton(
              Buttons.google,
              text: "Sign in with Google",
              onPressed: () async {
                try {
                  await signInWithGoogle();
                } catch (e) {
                  print(e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
