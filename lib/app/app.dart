import 'package:flutter/material.dart';

import '../core/theme/side_b_theme.dart';
import '../features/shell/presentation/main_shell.dart';

class SideBApp extends StatelessWidget {
  const SideBApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SIDE B',
    debugShowCheckedModeBanner: false,
    theme: SideBTheme.light,
    home: const MainShell(),
  );
}
