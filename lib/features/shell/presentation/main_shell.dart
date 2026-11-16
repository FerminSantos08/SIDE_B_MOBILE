import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth.dart';
import '../../content/presentation/content_screen.dart';
import '../../content/presentation/content_providers.dart';
import '../../content/presentation/reaction_providers.dart';
import '../../creation/presentation/creation_hub_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'side_b_bottom_navigation.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(reactionUpdatesProvider);
      ref.invalidate(selectedReactionProvider);
      ref.invalidate(postsProvider);
    }
  }

  void _selectDestination(int index) {
    if (index == 0 || index == 1) {
      ref.invalidate(reactionUpdatesProvider);
      ref.invalidate(postsProvider);
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final canPublish =
        ref.watch(authProvider).asData?.value?.canPublish ?? false;
    final pages = [
      const ContentScreen(mode: ContentMode.home),
      const ContentScreen(mode: ContentMode.editorial),
      canPublish
          ? const CreationHubScreen()
          : const ContentScreen(mode: ContentMode.artists),
      const ContentScreen(mode: ContentMode.catalog),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SideBBottomNavigation(
              selectedIndex: _index,
              showCreateDestination: canPublish,
              onDestinationSelected: _selectDestination,
            ),
          ),
        ],
      ),
    );
  }
}
