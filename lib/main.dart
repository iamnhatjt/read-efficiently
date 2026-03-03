import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'providers/app_providers.dart';
import 'features/home/home_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/pdf_reader/pdf_reader_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/statistics/statistics_screen.dart';

// Conditionally import window_manager for desktop
import 'platform/desktop_window.dart'
    if (dart.library.html) 'platform/web_window.dart'
    as window_helper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize pdfrx cache directory (required before using PdfDocument directly)
  await pdfrxFlutterInitialize();

  // Initialize Hive storage
  final storage = StorageService();
  await storage.init();

  // Initialize window manager for desktop platforms only
  if (!kIsWeb) {
    await window_helper.initDesktopWindow();
  }

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const VibeReadApp(),
    ),
  );
}

/// App router configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/reader', builder: (context, state) => const ReaderScreen()),
    GoRoute(
      path: '/pdf-reader',
      builder: (context, state) {
        final filePath = state.extra as String?;
        return PdfReaderScreen(initialFilePath: filePath);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
  ],
);

/// Root application widget
class VibeReadApp extends StatelessWidget {
  const VibeReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VibeRead',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      builder: (context, child) {
        final topInset = MediaQuery.paddingOf(context).top;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.bgPrimary),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topInset + 84,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66FF8F5E),
                        Color(0x220D0D0D),
                        Color(0x000D0D0D),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
