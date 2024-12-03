import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'mypage_screen.dart';
import 'reflection_screen.dart';
import 'setting_screen.dart';
import 'tutorial_screen.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../providers/user_data_provider.dart';

class MainScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    // チュートリアルのフラグを監視
    final userData = ref.watch(userDataProvider);

    final pages = [
      MypageScreen(onNavigate: (index) => selectedIndex.value = index),
      ReflectionScreen(onNavigate: (index) => selectedIndex.value = index),
      SettingsScreen(onNavigate: (index) => selectedIndex.value = index),
    ];

    final titles = ['マイメモ', 'みんなの記録', '設定'];

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
