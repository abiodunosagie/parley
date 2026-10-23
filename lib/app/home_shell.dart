// FILE: app/home_shell.dart
// The bottom tab bar that holds the four features: Chat, Look, Extract, Tasks.
// Shown only when someone is signed in (see auth_gate.dart).

import 'package:flutter/material.dart';

import '../features/agent/agent_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/extract/extract_screen.dart';
import '../features/vision/vision_screen.dart';
import 'theme.dart';

/// The four features as tabs. IndexedStack keeps each tab's widgets (scroll position, typed
/// text) when you switch away. Replies keep running because their Riverpod providers live on.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _tabs = [
    _Tab('Chat', Icons.forum_outlined, Icons.forum),
    _Tab('Look', Icons.camera_alt_outlined, Icons.camera_alt),
    _Tab('Extract', Icons.document_scanner_outlined, Icons.document_scanner),
    _Tab('Tasks', Icons.task_alt_outlined, Icons.task_alt),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          ChatScreen(),
          VisionScreen(),
          ExtractScreen(),
          AgentScreen(),
        ],
      ),
      bottomNavigationBar: _TabBar(
        tabs: _tabs,
        selected: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A flat tab bar: a hairline on top, the selected tab in the accent colour with a short bar
/// above it. No pill-shaped highlight, so it reads the same in light and dark mode.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });
  final List<_Tab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selected,
                    button: true,
                    label: tabs[i].label,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      child: _TabItem(tab: tabs[i], active: i == selected),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.active});
  final _Tab tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.accent : colors.muted;
    return ExcludeSemantics(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: active ? 28 : 0,
            color: colors.accent,
          ),
          const SizedBox(height: 8),
          Icon(active ? tab.selectedIcon : tab.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
