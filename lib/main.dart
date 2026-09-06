import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Noto — Your notes. Always local.
///
/// App entry point. The theme mode is held in a top-level
/// `ValueNotifier<ThemeMode>` and the whole `MaterialApp` rebuilds when
/// it changes via `ValueListenableBuilder`. This avoids pulling in a
/// full state-management package while still letting the Settings
/// screen flip the theme app-wide.
///
/// The same notifier is handed to [HomeScreen], which forwards it on to
/// the Settings screen so the dark-mode toggle has something to flip.
void main() {
  runApp(const NotoApp());
}

class NotoApp extends StatelessWidget {
  const NotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Noto',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: HomeScreen(themeNotifier: themeNotifier),
        );
      },
    );
  }
}
