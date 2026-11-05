import 'package:flutter/material.dart';

import '../../content/presentation/content_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'side_b_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [
    ContentScreen(mode: ContentMode.home),
    ContentScreen(mode: ContentMode.editorial),
    ContentScreen(mode: ContentMode.artists),
    ContentScreen(mode: ContentMode.catalog),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: IndexedStack(index: _index, children: _pages)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SideBBottomNavigation(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
            ),
          ),
        ],
      ),
    );
  }
}
