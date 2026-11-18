import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:side_b/app/app.dart';
import 'package:side_b/features/auth/auth.dart';
import 'package:side_b/features/content/presentation/content_providers.dart';
import 'package:side_b/features/shell/presentation/side_b_bottom_navigation.dart';

class _Guest extends AuthController {
  @override
  Future<AuthUser?> build() async => null;
}

void main() {
  testWidgets('renders SIDE B navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          postsProvider.overrideWith((ref) => []),
          artistsProvider.overrideWith((ref) => []),
          productsProvider.overrideWith((ref) => []),
          authProvider.overrideWith(_Guest.new),
        ],
        child: const SideBApp(),
      ),
    );
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.bySemanticsLabel('Editorial'), findsOneWidget);

    for (final label in [
      'Editorial',
      'Artistas',
      'Tienda',
      'Perfil',
      'Inicio',
    ]) {
      await tester.tap(find.byKey(ValueKey('side-b-nav-$label')));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('side-b-nav-Tienda')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(find.byType(SideBBottomNavigation), findsNothing);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(SideBBottomNavigation), findsOneWidget);
  });

  testWidgets('keeps the floating navigation within its maximum width', (
    tester,
  ) async {
    const surfaces = [
      Size(320, 800),
      Size(360, 800),
      Size(412, 800),
      Size(600, 900),
      Size(900, 800),
      Size(900, 600),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final surface in surfaces) {
      tester.view.physicalSize = surface;
      await tester.binding.setSurfaceSize(surface);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SideBBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: _ignoreSelection,
            ),
          ),
        ),
      );

      final size = tester.getSize(
        find.byKey(const ValueKey('side-b-bottom-navigation-pill')),
      );
      expect(size.width, lessThanOrEqualTo(380));
      expect(size.width, lessThanOrEqualTo(surface.width - 32));
      expect(size.height, 64);
      expect(
        tester.getSize(find.byKey(const ValueKey('side-b-nav-Inicio'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getCenter(find.byKey(const ValueKey('side-b-selected-Inicio')))
            .dy,
        closeTo(
          tester
              .getCenter(
                find.byKey(const ValueKey('side-b-bottom-navigation-pill')),
              )
              .dy,
          .1,
        ),
      );
      expect(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('side-b-bottom-navigation-pill')),
            )
            .dy,
        closeTo(surface.height - 16, .1),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}

void _ignoreSelection(int _) {}
