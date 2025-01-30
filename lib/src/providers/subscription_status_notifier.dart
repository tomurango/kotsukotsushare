import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionStatusNotifier extends StateNotifier<bool> {
  SubscriptionStatusNotifier() : super(false) {
    // 初期化時に課金状態をチェック
    checkUserPlan();

    // 課金状態の変更をリッスン
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateSubscriptionStatus(customerInfo);
    });
  }

  Future<void> checkUserPlan() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionStatus(customerInfo);
    } catch (e) {
      print('Error fetching customer info: $e');
      state = false; // エラー時はデフォルトで非課金状態にする
    }
  }

  void _updateSubscriptionStatus(CustomerInfo customerInfo) {
    state = customerInfo.entitlements.active.containsKey('premium');
  }
}

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, bool>((ref) {
  return SubscriptionStatusNotifier();
});
