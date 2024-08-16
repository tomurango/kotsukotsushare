import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mypage_screen.dart';
import 'share_screen.dart';
import 'setting_screen.dart';
import 'create_kotsukotsu_screen.dart';
import 'login_screen.dart';
import '../widgets/custom_bottom_app_bar.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 配列の順番がページに対応する番号であり、CustomBottomAppBarのindexとも対応している
    _pages = [
      MypageScreen(onNavigate: _navigateTo),
      ShareScreen(onNavigate: _navigateTo),
      SettingScreen(onNavigate: _navigateTo),
    ];
  }

  final List<String> _titles = [
    'Mypage',
    'Share',
    'Create KotsuKotsu',
  ];

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomAppBar(
        onNavigate: _navigateTo,
        selectedIndex: _selectedIndex,
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
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
