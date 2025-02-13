import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'mypage_screen.dart';
import 'question_board_screen.dart';
import 'setting_screen.dart';
import 'tutorial_screen.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/question/question_fab.dart';
import '../widgets/question/question_bottom_sheet.dart';
import '../providers/user_data_provider.dart';

class MainScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    // チュートリアルのフラグを監視
    final userData = ref.watch(userDataProvider);

    final pages = [
      MypageScreen(onNavigate: (index) => selectedIndex.value = index),
      //ReflectionScreen(onNavigate: (index) => selectedIndex.value = index),
      QuestionBoardScreen(onNavigate: (index) => selectedIndex.value = index),
      SettingsScreen(onNavigate: (index) => selectedIndex.value = index),
    ];

    final titles = ['マイメモ', '質問掲示板', '設定'];

    // チュートリアル表示
    useEffect(() {
      if (userData.asData?.value?['tutorialCompleted'] == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTutorialScreen(context);
        });
      }
      return null;
    }, [userData]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF008080),
        title: Text(
          titles[selectedIndex.value],
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: pages[selectedIndex.value],
      bottomNavigationBar: CustomBottomAppBar(
        onNavigate: (index) => selectedIndex.value = index,
        selectedIndex: selectedIndex.value,
      ),
      floatingActionButton: selectedIndex.value == 1
        ? Container(
            margin: EdgeInsets.only(bottom: 70), // ← ここで高さを調整（30px 上に移動）
            child: QuestionFAB(onNavigate: (index) => selectedIndex.value = index),
          )
        : null,
      // 右下
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomSheet: selectedIndex.value == 1
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4, // 画面の40%まで
              ),
              child: QuestionBottomSheet(),
            )
          : null,
    );
  }

  void _showTutorialScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TutorialScreen(),
      ),
    );
  }
}
