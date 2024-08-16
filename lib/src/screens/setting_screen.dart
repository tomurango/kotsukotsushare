import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SettingScreen extends StatelessWidget {
  final Function(int) onNavigate;

  SettingScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
        child: Text('Logout'),
      ),
    );
  }
}
