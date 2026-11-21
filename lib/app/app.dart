import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/side_b_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/shell/presentation/main_shell.dart';

class SideBApp extends ConsumerWidget {
  const SideBApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'SIDE B',
    debugShowCheckedModeBanner: false,
    theme: SideBTheme.light,
    darkTheme: SideBTheme.dark,
    themeMode: ref.watch(darkThemeProvider) ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) {
      final theme = Theme.of(context);
      final brightness = theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness,
          systemNavigationBarColor: theme.scaffoldBackgroundColor,
          systemNavigationBarIconBrightness: brightness,
          systemNavigationBarContrastEnforced: false,
        ),
        child: child!,
      );
    },
    home: const MainShell(),
  );
}
