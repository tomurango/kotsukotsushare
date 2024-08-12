import 'package:flutter/material.dart';

class MypageScreen extends StatelessWidget {
  final Function(int) onNavigate;

  MypageScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('マイページ'),
    );
  }
}
