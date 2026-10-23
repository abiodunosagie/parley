import 'package:flutter/material.dart';

import '../features/agent/agent_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/extract/extract_screen.dart';
import '../features/vision/vision_screen.dart';

/// The four features as tabs. IndexedStack keeps each tab's widgets (scroll position, typed
/// text) when you switch away. Replies keep running because their Riverpod providers live on.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [ChatScreen(), VisionScreen(), ExtractScreen(), AgentScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'Look'),
          NavigationDestination(icon: Icon(Icons.data_object), label: 'Extract'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
        ],
      ),
    );
  }
}
