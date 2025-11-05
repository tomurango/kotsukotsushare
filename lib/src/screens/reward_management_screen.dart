import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/monthly_contribution_data.dart';
import '../models/monthly_pool_data.dart';
import '../models/answer_reward_data.dart';
import 'reward_withdrawal_screen.dart';

class RewardManagementScreen extends HookConsumerWidget {
  const RewardManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentPeriod = _getCurrentPeriod();

    final contributionState = useState<MonthlyContributionData?>(null);
    final poolState = useState<MonthlyPoolData?>(null);
    final rewardsState = useState<List<AnswerRewardData>>([]);
    final isLoading = useState<bool>(true);
    final virtualReward = useState<int>(0);

    useEffect(() {
      _loadRewardData() async {
        if (currentUser == null) return;

        try {
          final db = FirebaseFirestore.instance;

          // 今月の貢献度を取得
          final contributionDoc = await db
              .collection('monthly_contributions')
              .doc(currentPeriod)
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (contributionDoc.exists) {
            contributionState.value = MonthlyContributionData.fromFirestore(contributionDoc);
          }

          // 今月のプールを取得
          final poolDoc = await db
              .collection('monthly_pools')
              .doc(currentPeriod)
              .get();

          if (poolDoc.exists) {
            poolState.value = MonthlyPoolData.fromFirestore(poolDoc);
          }

          // 仮想報酬を計算
          if (contributionState.value != null && poolState.value != null) {
            // 全ユーザーの総ポイントを取得
            final allContributionsSnapshot = await db
                .collection('monthly_contributions')
                .doc(currentPeriod)
                .collection('users')
                .get();

            int totalPoints = 0;
            for (var doc in allContributionsSnapshot.docs) {
              final data = doc.data();
              totalPoints += (data['total_points'] ?? 0) as int;
            }

            if (totalPoints > 0) {
              final userPoints = contributionState.value!.totalPoints;
              final poolAmount = poolState.value!.poolAmount;
              virtualReward.value = (poolAmount * userPoints ~/ totalPoints);
            }
          }

          // 過去の報酬履歴を取得
          final rewardsSnapshot = await db
              .collection('answer_rewards')
              .where('user_id', isEqualTo: currentUser.uid)
              .orderBy('created_at', descending: true)
              .limit(10)
              .get();

          rewardsState.value = rewardsSnapshot.docs
              .map((doc) => AnswerRewardData.fromFirestore(doc))
              .toList();

          isLoading.value = false;
        } catch (e) {
          print('報酬データの読み込みエラー: $e');
          isLoading.value = false;
        }
      }

      _loadRewardData();
      return null;
    }, [currentUser?.uid]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('報酬管理'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今月の貢献度カード
                  _ContributionCard(
                    contribution: contributionState.value,
                    period: currentPeriod,
                  ),
                  const SizedBox(height: 16),

                  // 獲得予定報酬カード
                  _VirtualRewardCard(
                    virtualReward: virtualReward.value,
                    pool: poolState.value,
                    contribution: contributionState.value,
                  ),
                  const SizedBox(height: 16),

                  // 報酬引き出しボタン
                  if (virtualReward.value > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RewardWithdrawalScreen(
                                availableAmount: virtualReward.value,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('報酬を引き出す'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 過去の報酬履歴
                  const Text(
                    '報酬履歴',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _RewardHistoryList(rewards: rewardsState.value),
                ],
              ),
            ),
    );
  }

  String _getCurrentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

// 今月の貢献度カード
class _ContributionCard extends StatelessWidget {
  final MonthlyContributionData? contribution;
  final String period;

  const _ContributionCard({
    required this.contribution,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (contribution == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$period の貢献度',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'まだ回答がありません',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$period の貢献度',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.star,
                  label: '総ポイント',
                  value: '${contribution!.totalPoints} pt',
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.chat_bubble,
                  label: '回答数',
                  value: '${contribution!.answerCount}件',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.emoji_events,
                  label: 'ベストアンサー',
                  value: '${contribution!.bestAnswerCount}件',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 統計アイテム
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// 獲得予定報酬カード
class _VirtualRewardCard extends StatelessWidget {
  final int virtualReward;
  final MonthlyPoolData? pool;
  final MonthlyContributionData? contribution;

  const _VirtualRewardCard({
    required this.virtualReward,
    required this.pool,
    required this.contribution,
  });

  @override
  Widget build(BuildContext context) {
    final isTestPeriod = pool?.isTestPeriod ?? true;

    return Card(
      color: Colors.green[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '獲得予定報酬',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contribution == null)
              const Text(
                '回答を投稿すると報酬が発生します',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¥${virtualReward.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]},')}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isTestPeriod)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'テスト期間中のため実際の振込はありません',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'プール総額: ¥${pool?.poolAmount ?? 0} / ${pool?.unlockCount ?? 0}アンロック',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// 報酬履歴リスト
class _RewardHistoryList extends StatelessWidget {
  final List<AnswerRewardData> rewards;

  const _RewardHistoryList({required this.rewards});

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '報酬履歴がありません',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: rewards.map((reward) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: reward.status == RewardStatus.test
                  ? Colors.orange
                  : Colors.green,
              child: const Icon(Icons.monetization_on, color: Colors.white),
            ),
            title: Text(
              '¥${reward.rewardAmount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${reward.period} / ${reward.contributionPoints}pt ${reward.isBestAnswerer ? '★' : ''}',
            ),
            trailing: Chip(
              label: Text(
                reward.status.displayName,
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: reward.status == RewardStatus.test
                  ? Colors.orange[100]
                  : Colors.green[100],
            ),
          ),
        );
      }).toList(),
    );
  }
}
