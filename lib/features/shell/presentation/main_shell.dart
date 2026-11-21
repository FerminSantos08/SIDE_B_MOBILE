import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
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
  Timer? _editorialRefresh;
  bool _hasInnerRoute = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _section = ValueNotifier(0);

  Route<void> _initialRoute(RouteSettings settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => _SectionPages(section: _section),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorialRefresh?.cancel();
    _section.dispose();
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
    _editorialRefresh?.cancel();
    if (index == 0 || index == 1) {
      // Let the indicator finish moving before rebuilding the editorial feed.
      final duration = index == _index
          ? Duration.zero
          : SideBBottomNavigation.animationDuration;
      _editorialRefresh = Timer(duration, () {
        ref.invalidate(reactionUpdatesProvider);
        ref.invalidate(postsProvider);
      });
    }
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _section.value = index;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final canPublish =
        ref.watch(authProvider).asData?.value?.canPublish ?? false;
    final showNavigation = MediaQuery.viewInsetsOf(context).bottom == 0;
    final navigationFootprint =
        SideBBottomNavigation.bottomFootprint +
        MediaQuery.paddingOf(context).bottom;
    final background = Theme.of(context).scaffoldBackgroundColor;
    const halfPill = SideBBottomNavigation.height / 2;
    const contentOverlap = halfPill + 6;
    return PopScope(
      canPop: _index == 0 || _hasInnerRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_hasInnerRoute && _index != 0) _selectDestination(0);
      },
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: showNavigation
                    ? navigationFootprint - contentOverlap
                    : 0,
              ),
              child: NavigatorPopHandler<Object?>(
                onPopWithResult: (result) {
                  if (_hasInnerRoute)
                    _navigatorKey.currentState?.maybePop(result);
                },
                child: NotificationListener<NavigationNotification>(
                  onNotification: (notification) {
                    if (_hasInnerRoute != notification.canHandlePop) {
                      setState(
                        () => _hasInnerRoute = notification.canHandlePop,
                      );
                    }
                    return false;
                  },
                  child: Material(
                    color: background,
                    child: Navigator(
                      key: _navigatorKey,
                      onGenerateRoute: _initialRoute,
                    ),
                  ),
                ),
              ),
            ),
            if (showNavigation)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: navigationFootprint - halfPill,
                child: IgnorePointer(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              background.withValues(alpha: 0),
                              background.withValues(alpha: .72),
                              background,
                            ],
                            stops: const [0, .42, .9],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showNavigation)
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
      ),
    );
  }
}

class _SectionPages extends ConsumerWidget {
  const _SectionPages({required this.section});

  final ValueListenable<int> section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<int>(
        valueListenable: section,
        builder: (context, index, child) => IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < pages.length; i++)
              TickerMode(enabled: i == index, child: pages[i]),
          ],
        ),
      ),
    );
  }
}
