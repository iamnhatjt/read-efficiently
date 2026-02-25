/// App-wide constants for VibeRead
class AppConstants {
  // ── App Info ──
  static const String appName = 'VibeRead';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Speed Read Everything.';

  // ── Reading defaults ──
  static const int defaultWpm = 300;
  static const int minWpm = 100;
  static const int maxWpm = 1200;
  static const int wpmStep = 50;

  static const int defaultWordsAtATime = 1;
  static const int minWordsAtATime = 1;
  static const int maxWordsAtATime = 5;

  static const double defaultFontSize = 48.0;
  static const double minFontSize = 24.0;
  static const double maxFontSize = 96.0;

  // ── Auto-save interval ──
  static const int autoSaveIntervalSeconds = 5;

  // ── Hive box names ──
  static const String hiveProgressBox = 'reading_progress';
  static const String hiveSettingsBox = 'app_settings';
  static const String hiveStatsBox = 'reading_stats';
  static const String hiveRecentBox = 'recent_documents';

  // ── Available fonts for reading ──
  static const List<String> readingFonts = [
    'Inter',
    'Georgia',
    'Literata',
    'Merriweather',
    'Lora',
    'Roboto Slab',
    'Source Serif 4',
    'Noto Serif',
    'IBM Plex Serif',
    'Crimson Text',
  ];
}
