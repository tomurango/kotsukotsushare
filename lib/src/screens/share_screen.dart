import 'package:flutter/material.dart';

class ShareScreen extends StatelessWidget {
  final Function(int) onNavigate;

  ShareScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Share Screen'),
    );
  }
}
