import 'package:flutter/material.dart';

class CustomBottomAppBar extends StatelessWidget {
  final Function(int) onNavigate;
  final int selectedIndex;

  CustomBottomAppBar({required this.onNavigate, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: 'マイメモ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '質問掲示板',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights),
          label: 'レポート',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '設定',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: onNavigate,
    );
  }
}
