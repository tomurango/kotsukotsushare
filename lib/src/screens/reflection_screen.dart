import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/public_memos_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reflection_provider.dart';

class ReflectionScreen extends StatelessWidget {
  final Function(int) onNavigate;

  ReflectionScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // タブの数
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reflection'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'My Reflections'),
              Tab(text: 'Others\' Memos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReflectionHistoryTab(), // 内省記録を表示するタブ
            _OthersMemosTab(),       // 公開メモを表示するタブ
          ],
        ),
      ),
    );
  }
}

class _ReflectionHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のユーザーをRiverpodのProviderから取得
    final user = ref.watch(userProvider);

    if (user == null) {
      return Center(child: Text('No user logged in.'));
    }

    // Reflectionデータを取得
    final reflectionsAsyncValue = ref.watch(reflectionsProvider(user.uid));

    return Scaffold(
      body: reflectionsAsyncValue.when(
        data: (reflections) {
          if (reflections.isEmpty) {
            return Center(child: Text('No reflections found.'));
          }
          return ListView.builder(
            itemCount: reflections.length,
            itemBuilder: (context, index) {
              final reflection = reflections[index];
              return ListTile(
                title: Text(reflection.memoContent), // 元のメモ
                subtitle: Text(reflection.reflection), // 内省内容
                trailing: Text(reflection.createdAt.toString()),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}


class _OthersMemosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsyncValue = ref.watch(publicMemosProvider);

    return Scaffold(
      body: memoAsyncValue.when(
        data: (memos) {
          if (memos.isEmpty) {
            return Center(child: Text('No public memos found.'));
          }
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return ListTile(
                title: Text(memo.content),
                subtitle: Text('Anonymous'),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
