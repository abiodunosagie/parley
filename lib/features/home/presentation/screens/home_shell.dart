// FILE: features/home/presentation/screens/home_shell.dart
// The frame around the five tabs. GoRouter's StatefulShellRoute keeps each tab's screen alive
// (scroll position, typed text) when you switch away; this widget only draws the tab bar and
// tells the router which tab you tapped.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/parley_tab_bar.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Same order as the branches in app/router/app_router.dart.
  static const destinations = [
    TabDestination('Chat', Icons.forum_outlined, Icons.forum),
    TabDestination('Look', Icons.camera_alt_outlined, Icons.camera_alt),
    TabDestination('Read', Icons.picture_as_pdf_outlined, Icons.picture_as_pdf),
    TabDestination('Tasks', Icons.task_alt_outlined, Icons.task_alt),
    TabDestination('Tools', Icons.widgets_outlined, Icons.widgets),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ParleyTabBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        // Tapping the current tab again returns it to its first screen, like iOS tab bars.
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
