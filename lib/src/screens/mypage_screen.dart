import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class MypageScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  MypageScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userProvider);

    return Center(
      child: userName != null
          ? Text('ログイン中のユーザー: $userName')
          : Text('ログインしていません'),
    );
  }
}
