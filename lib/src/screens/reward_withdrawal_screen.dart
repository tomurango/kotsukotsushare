import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reward_withdrawal_data.dart';
import '../services/local_database.dart';

class RewardWithdrawalScreen extends HookConsumerWidget {
  final int availableAmount;

  const RewardWithdrawalScreen({
    Key? key,
    required this.availableAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bankNameController = useTextEditingController();
    final bankBranchController = useTextEditingController();
    final accountNumberController = useTextEditingController();
    final accountHolderController = useTextEditingController();
    final selectedAccountType = useState<String>('普通');
    final isSubmitting = useState<bool>(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('報酬引き出し'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // テスト期間の警告
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'テスト期間中のため実際の振込は行われません\n申請内容は記録されますが、振込処理は実行されません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 引き出し額表示
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '引き出し可能額',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${availableAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]},')}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 銀行情報入力フォーム
            const Text(
              '振込先情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 銀行名
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(
                labelText: '銀行名',
                hintText: '例: 三菱UFJ銀行',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 支店名
            TextField(
              controller: bankBranchController,
              decoration: const InputDecoration(
                labelText: '支店名',
                hintText: '例: 新宿支店',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 口座種別
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '口座種別',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('普通'),
                        value: '普通',
                        groupValue: selectedAccountType.value,
                        onChanged: (value) {
                          if (value != null) {
                            selectedAccountType.value = value;
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('当座'),
                        value: '当座',
                        groupValue: selectedAccountType.value,
                        onChanged: (value) {
                          if (value != null) {
                            selectedAccountType.value = value;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 口座番号
            TextField(
              controller: accountNumberController,
              decoration: const InputDecoration(
                labelText: '口座番号',
                hintText: '例: 1234567',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 口座名義
            TextField(
              controller: accountHolderController,
              decoration: const InputDecoration(
                labelText: '口座名義（カタカナ）',
                hintText: '例: ヤマダタロウ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // 引き出し申請ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting.value
                    ? null
                    : () => _submitWithdrawalRequest(
                          context,
                          currentUser,
                          bankNameController.text,
                          bankBranchController.text,
                          selectedAccountType.value,
                          accountNumberController.text,
                          accountHolderController.text,
                          isSubmitting,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '引き出しを申請する（テスト）',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '注意事項',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• テスト期間中は実際の振込処理は行われません\n'
                    '• 申請内容は記録され、管理画面から確認できます\n'
                    '• 本リリース後は審査の上、振込処理を行います\n'
                    '• 振込手数料はプラットフォームが負担します',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWithdrawalRequest(
    BuildContext context,
    User? currentUser,
    String bankName,
    String bankBranch,
    String accountType,
    String accountNumber,
    String accountHolder,
    ValueNotifier<bool> isSubmitting,
  ) async {
    // バリデーション
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインが必要です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (availableAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('引き出し可能額がありません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (bankName.isEmpty ||
        bankBranch.isEmpty ||
        accountNumber.isEmpty ||
        accountHolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべての項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('引き出し申請確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('引き出し額: ¥$availableAmount'),
            const SizedBox(height: 8),
            Text('銀行名: $bankName'),
            Text('支店名: $bankBranch'),
            Text('口座種別: $accountType'),
            Text('口座番号: $accountNumber'),
            Text('口座名義: $accountHolder'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'テスト期間中のため実際の振込は行われません',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
            ),
            child: const Text('申請する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isSubmitting.value = true;

    try {
      final db = FirebaseFirestore.instance;
      final withdrawalId = db.collection('reward_withdrawals').doc().id;

      final withdrawalData = RewardWithdrawalData(
        id: withdrawalId,
        userId: currentUser.uid,
        amount: availableAmount,
        bankName: bankName,
        bankBranch: bankBranch,
        accountType: accountType,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        status: WithdrawalStatus.test, // テスト期間中はtestステータス
        createdAt: DateTime.now(),
      );

      await db
          .collection('reward_withdrawals')
          .doc(withdrawalId)
          .set(withdrawalData.toFirestore());

      // ローカルDBにも保存
      await LocalDatabase.insertRewardWithdrawal(withdrawalData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('引き出し申請を受け付けました（テスト期間中・振込なし）'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // 報酬管理画面に戻る
      Navigator.of(context).pop();
    } catch (e) {
      print('引き出し申請エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('引き出し申請に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
