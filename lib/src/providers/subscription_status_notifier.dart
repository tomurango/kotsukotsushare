import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionStatusNotifier extends StateNotifier<bool> {
  SubscriptionStatusNotifier() : super(false) {
    // 初期化時に課金状態をチェック
    checkUserPlan();
  }

  Future<void> checkUserPlan() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // 'premium' が有効な場合に true、それ以外は false
      state = customerInfo.entitlements.active.containsKey('premium');
    } catch (e) {
      print('Error fetching customer info: $e');
      state = false; // エラー時はデフォルトで非課金状態にする
    }
  }
}

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, bool>((ref) {
  return SubscriptionStatusNotifier();
});
