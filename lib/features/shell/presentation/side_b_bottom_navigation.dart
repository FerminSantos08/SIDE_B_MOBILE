import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/side_b_theme.dart';

/// Floating, compact navigation for the five primary SIDE B destinations.
///
/// The bar has a fixed maximum width so it stays proportioned on tablets.
/// [selectedIndex] is owned by the parent shell to keep navigation state and
/// page preservation independent from this visual component.
class SideBBottomNavigation extends StatelessWidget {
  const SideBBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showCreateDestination = false,
    super.key,
  });

  static const maxWidth = 380.0;
  static const height = 64.0;
  static const bottomMargin = 16.0;
  static const bottomFootprint = height + bottomMargin;
  static const _horizontalScreenMargin = 16.0;
  static const animationDuration = Duration(milliseconds: 280);
  static const _animationCurve = Curves.easeInOutCubic;
  static const _minimumInactiveItemWidth = 48.0;
  static const _verticalInset = 6.0;
  static const _indicatorHorizontalInset = 5.0;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showCreateDestination;

  static const _standardDestinations = [
    _NavigationDestination(LucideIcons.home, 'Inicio'),
    _NavigationDestination(LucideIcons.newspaper, 'Editorial'),
    _NavigationDestination(LucideIcons.disc3, 'Artistas'),
    _NavigationDestination(LucideIcons.shoppingBag, 'Tienda'),
    _NavigationDestination(LucideIcons.user, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _standardDestinations[0],
      _standardDestinations[1],
      if (showCreateDestination)
        const _NavigationDestination(
          Icons.add_circle_outline,
          'Crear',
          isCreation: true,
        )
      else
        _standardDestinations[2],
      _standardDestinations[3],
      _standardDestinations[4],
    ];
    assert(selectedIndex >= 0 && selectedIndex < destinations.length);

    final availableWidth =
        MediaQuery.sizeOf(context).width - (_horizontalScreenMargin * 2);
    final navigationWidth = availableWidth.clamp(0.0, maxWidth).toDouble();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: bottomMargin),
        child: Align(
          alignment: Alignment.center,
          // Scaffold positions bottomNavigationBar at the bottom. Shrinking
          // this Align vertically prevents it from consuming the viewport and
          // consequently placing the pill in the middle on wide layouts.
          heightFactor: 1,
          child: SizedBox(
            key: const ValueKey('side-b-bottom-navigation-pill'),
            width: navigationWidth,
            height: height,
            child: Material(
              color: SideBColors.graphite,
              borderRadius: BorderRadius.circular(height / 2),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final activeWidth = _activeItemWidth(constraints.maxWidth);
                  final inactiveWidth =
                      (constraints.maxWidth - activeWidth) /
                      (destinations.length - 1);
                  final indicatorLeft = _itemLeft(
                    selectedIndex,
                    selectedIndex,
                    activeWidth,
                    inactiveWidth,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        key: const ValueKey('side-b-nav-indicator'),
                        duration: animationDuration,
                        curve: _animationCurve,
                        left: indicatorLeft + _indicatorHorizontalInset,
                        top: _verticalInset,
                        width: activeWidth - (_indicatorHorizontalInset * 2),
                        height: height - (_verticalInset * 2),
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: destinations[selectedIndex].isCreation
                                  ? SideBColors.terracotta
                                  : SideBColors.olive,
                              borderRadius: BorderRadius.circular(height / 2),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(destinations.length, (index) {
                        final selected = index == selectedIndex;
                        return AnimatedPositioned(
                          duration: animationDuration,
                          curve: _animationCurve,
                          left: _itemLeft(
                            index,
                            selectedIndex,
                            activeWidth,
                            inactiveWidth,
                          ),
                          // Destinations always occupy the full pill. Only the
                          // indicator is inset, so icons and labels retain a
                          // fixed optical center while it moves beneath them.
                          top: 0,
                          bottom: 0,
                          width: selected ? activeWidth : inactiveWidth,
                          child: _NavigationItem(
                            destination: destinations[index],
                            selected: selected,
                            onTap: () => onDestinationSelected(index),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _activeItemWidth(double availableWidth) {
    final preferredWidth = (availableWidth * .35).clamp(96.0, 132.0);
    final widthForAccessibleItems =
        (availableWidth -
                (_minimumInactiveItemWidth *
                    (_standardDestinations.length - 1)))
            .clamp(0.0, double.infinity);
    return preferredWidth.clamp(0.0, widthForAccessibleItems).toDouble();
  }

  double _itemLeft(
    int index,
    int activeIndex,
    double activeWidth,
    double inactiveWidth,
  ) {
    if (index <= activeIndex) return index * inactiveWidth;
    return activeWidth + ((index - 1) * inactiveWidth);
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: SideBColors.ivory,
      fontSize: 11,
      height: 1,
      letterSpacing: .2,
    );

    return Semantics(
      key: ValueKey('side-b-nav-${destination.label}'),
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Row(
                key: ValueKey('side-b-selected-${destination.label}'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    destination.icon,
                    color: destination.isCreation && !selected
                        ? SideBColors.terracotta
                        : SideBColors.ivory,
                    size: 20,
                  ),
                  Flexible(
                    child: AnimatedSize(
                      duration: SideBBottomNavigation.animationDuration,
                      curve: SideBBottomNavigation._animationCurve,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Text(
                                destination.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination(
    this.icon,
    this.label, {
    this.isCreation = false,
  });

  final IconData icon;
  final String label;
  final bool isCreation;
}
