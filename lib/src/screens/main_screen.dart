import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'mypage_screen.dart';
import 'share_screen.dart';
import 'setting_screen.dart';
import 'create_kotsukotsu_screen.dart';
import '../widgets/custom_bottom_app_bar.dart';

class MainScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // useStateで_statefulWidgetのようにローカル状態を管理
    final selectedIndex = useState(0);

    // ページのリストを設定
    final pages = [
      MypageScreen(onNavigate: (index) => selectedIndex.value = index),
      ShareScreen(onNavigate: (index) => selectedIndex.value = index),
      SettingScreen(onNavigate: (index) => selectedIndex.value = index),
    ];

    // タイトルのリスト
    final titles = ['Mypage', 'Share', 'Create KotsuKotsu'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex.value]),
      ),
      body: pages[selectedIndex.value],
      bottomNavigationBar: CustomBottomAppBar(
        onNavigate: (index) => selectedIndex.value = index,
        selectedIndex: selectedIndex.value,
      ),
      floatingActionButton: selectedIndex.value == 0 || selectedIndex.value == 1
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateKotsuKotsuScreen()),
              );
            },
            tooltip: 'Create KotsuKotsu',
            child: Icon(Icons.add),
          )
        : null,
    );
  }
}
