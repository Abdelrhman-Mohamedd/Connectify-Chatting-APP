import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/config/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.phone), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2), label: 'People'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, index),
      ),
    );
  }
}
