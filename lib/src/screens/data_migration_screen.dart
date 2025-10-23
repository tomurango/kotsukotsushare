import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/migration_service.dart';
import '../providers/local_data_provider.dart';

class DataMigrationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final migrationProgress = ref.watch(migrationProgressProvider);
    final useLocal = ref.watch(useLocalDataProvider);
    final migrationService = ref.read(migrationServiceProvider);
    final migrationCompleted = ref.read(useLocalDataProvider.notifier).migrationCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('データ移行'),
        backgroundColor: Color(0xFF008080),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明セクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ローカルデータ移行について',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'クラウド（Firebase）に保存されているカードとメモを、端末内のローカルストレージに移行します。',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'メリット:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• オフラインでも利用可能'),
                    Text('• アプリの動作が高速化'),
                    Text('• データの読み込み時間短縮'),
                    SizedBox(height: 12),
                    Text(
                      '注意事項:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    Text('• 質問掲示板機能は引き続きクラウドを使用'),
                    Text('• AI相談機能は引き続きクラウドを使用'),
                    Text('• 移行後はローカルデータが優先されます'),
                    if (migrationCompleted) ...[
                      SizedBox(height: 8),
                      Text(
                        '• 一度移行したデータはクラウドに戻すことはできません',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // 現在の状態表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在の状態',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          useLocal ? Icons.smartphone : Icons.cloud,
                          color: useLocal ? Colors.green : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                useLocal ? 'ローカルデータを使用中' : 'クラウドデータを使用中',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: useLocal ? Colors.green : Colors.blue,
                                ),
                              ),
                              if (migrationCompleted && useLocal)
                                Text(
                                  '（移行完了済み）',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // 移行プログレス表示
            if (migrationProgress.status == MigrationStatus.migrating) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'データ移行中...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: migrationProgress.progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008080)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'カード: ${migrationProgress.migratedCards}/${migrationProgress.totalCards}',
                      ),
                      Text(
                        'メモ: ${migrationProgress.migratedMemos}/${migrationProgress.totalMemos}',
                      ),
                      Text(
                        '進捗: ${(migrationProgress.progress * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // エラー表示
            if (migrationProgress.status == MigrationStatus.error) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'エラーが発生しました',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        migrationProgress.errorMessage ?? '不明なエラー',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // 完了表示
            if (migrationProgress.status == MigrationStatus.completed) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '移行完了',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('カード: ${migrationProgress.migratedCards}件'),
                      Text('メモ: ${migrationProgress.migratedMemos}件'),
                      Text('正常に移行されました。'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            Spacer(),

            // アクションボタン
            if (migrationProgress.status != MigrationStatus.migrating) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !useLocal && migrationProgress.status != MigrationStatus.migrating
                      ? () => _startMigration(context, ref, migrationService)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF008080),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    !useLocal ? '移行を開始' : '移行済み',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // ローカルデータ切り替えボタン（移行完了後は非表示）
              if (!migrationCompleted)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: migrationProgress.status != MigrationStatus.migrating
                        ? () => _toggleLocalData(context, ref)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF008080),
                      side: BorderSide(color: Color(0xFF008080)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      useLocal ? 'クラウドデータに戻す' : 'ローカルデータを使用',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _startMigration(BuildContext context, WidgetRef ref, MigrationService migrationService) async {
    try {
      // 確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('データ移行の確認'),
          content: Text(
            'クラウドからローカルにデータを移行します。\n'
            '移行中はアプリを閉じないでください。\n\n'
            '移行を開始しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('開始'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // 移行開始
        await migrationService.migrateFromFirestore();

        // 移行完了後、ローカルデータ使用に切り替え
        await ref.read(useLocalDataProvider.notifier).setUseLocal(true);

        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データ移行が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移行に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleLocalData(BuildContext context, WidgetRef ref) async {
    try {
      final currentUseLocal = ref.read(useLocalDataProvider);
      await ref.read(useLocalDataProvider.notifier).setUseLocal(!currentUseLocal);
    } catch (e) {
      // 移行完了後にクラウドに戻そうとした場合のエラー
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移行完了後はクラウドデータに戻すことはできません'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}