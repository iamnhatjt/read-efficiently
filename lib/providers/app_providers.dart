import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/services/storage_service.dart';
import '../core/utils/app_utils.dart';
import '../models/app_settings.dart';
import '../models/reading_progress.dart';
import '../models/reading_stats.dart';

// ─── Storage Service Provider ────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ─── App Settings Provider ───────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    state = _storage.loadSettings();
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _storage.saveSettings(settings);
  }

  Future<void> setWpm(int wpm) async {
    await update(state.copyWith(
        wpm: wpm.clamp(AppConstants.minWpm, AppConstants.maxWpm)));
  }

  Future<void> setWordsAtATime(int n) async {
    await update(state.copyWith(
        wordsAtATime:
            n.clamp(AppConstants.minWordsAtATime, AppConstants.maxWordsAtATime)));
  }

  Future<void> setFontSize(double size) async {
    await update(state.copyWith(
        fontSize:
            size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize)));
  }

  Future<void> setThemeIndex(int index) async {
    await update(state.copyWith(themeIndex: index));
  }

  Future<void> setFontFamily(String font) async {
    await update(state.copyWith(fontFamily: font));
  }

  Future<void> toggleContextLines() async {
    await update(state.copyWith(showContextLines: !state.showContextLines));
  }

  Future<void> toggleAutoPageTurn() async {
    await update(state.copyWith(autoPageTurn: !state.autoPageTurn));
  }

  Future<void> toggleTts() async {
    await update(state.copyWith(ttsEnabled: !state.ttsEnabled));
  }

  Future<void> setTtsSpeed(double speed) async {
    await update(state.copyWith(ttsSpeed: speed));
  }

  Future<void> toggleFocusMode() async {
    await update(state.copyWith(focusMode: !state.focusMode));
  }

  Future<void> toggleAlwaysOnTop() async {
    await update(state.copyWith(alwaysOnTop: !state.alwaysOnTop));
  }
}

// ─── Reading Stats Provider ──────────────────────────────────────────────────

final statsProvider =
    StateNotifierProvider<StatsNotifier, ReadingStats>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StatsNotifier(storage);
});

class StatsNotifier extends StateNotifier<ReadingStats> {
  final StorageService _storage;

  StatsNotifier(this._storage) : super(ReadingStats()) {
    _load();
  }

  void _load() {
    state = _storage.loadStats();
  }

  Future<void> addWordsRead(int count) async {
    final now = DateTime.now();
    final dayKey = _dayKeyFromDate(now);
    final weeklyWords = Map<String, int>.from(state.weeklyWords);
    weeklyWords[dayKey] = (weeklyWords[dayKey] ?? 0) + count;

    // Update streak
    int newStreak = state.currentStreak;
    if (state.lastSessionDate == null ||
        !_isSameDay(state.lastSessionDate!, now)) {
      if (state.lastSessionDate != null &&
          now.difference(state.lastSessionDate!).inDays == 1) {
        newStreak++;
      } else if (state.lastSessionDate == null ||
          now.difference(state.lastSessionDate!).inDays > 1) {
        newStreak = 1;
      }
    }

    state = state.copyWith(
      totalWordsRead: state.totalWordsRead + count,
      weeklyWords: weeklyWords,
      currentStreak: newStreak,
      longestStreak:
          newStreak > state.longestStreak ? newStreak : state.longestStreak,
      lastSessionDate: now,
    );
    await _storage.saveStats(state);
  }

  Future<void> addReadingTime(int seconds) async {
    state = state.copyWith(
      totalReadingTimeSeconds: state.totalReadingTimeSeconds + seconds,
    );
    await _storage.saveStats(state);
  }

  Future<void> completeSession() async {
    state = state.copyWith(
      totalSessionsCompleted: state.totalSessionsCompleted + 1,
    );
    await _storage.saveStats(state);
  }

  String _dayKeyFromDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Recent Documents Provider ───────────────────────────────────────────────

final recentDocumentsProvider =
    StateNotifierProvider<RecentDocumentsNotifier, List<ReadingProgress>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return RecentDocumentsNotifier(storage);
});

class RecentDocumentsNotifier extends StateNotifier<List<ReadingProgress>> {
  final StorageService _storage;

  RecentDocumentsNotifier(this._storage) : super([]) {
    refresh();
  }

  void refresh() {
    state = _storage.getRecentDocuments();
  }

  Future<void> remove(String hash) async {
    await _storage.removeFromRecent(hash);
    refresh();
  }
}

// ─── RSVP Reader State ───────────────────────────────────────────────────────

/// Represents the full state of the RSVP reader
class ReaderState {
  final List<String> words;           // all words in document
  final List<int> pageBoundaries;     // indices where pages start (for PDFs)
  final int currentWordIndex;
  final bool isPlaying;
  final String documentTitle;
  final String documentHash;
  final String documentType;          // 'pdf', 'text', 'url'
  final int currentPage;
  final int totalPages;
  final int wpm;
  final int wordsAtATime;
  final int themeIndex;
  final String fontFamily;
  final double fontSize;
  final bool isLoading;
  final String? error;

  const ReaderState({
    this.words = const [],
    this.pageBoundaries = const [],
    this.currentWordIndex = 0,
    this.isPlaying = false,
    this.documentTitle = '',
    this.documentHash = '',
    this.documentType = 'text',
    this.currentPage = 0,
    this.totalPages = 0,
    this.wpm = 300,
    this.wordsAtATime = 1,
    this.themeIndex = 0,
    this.fontFamily = 'Inter',
    this.fontSize = 48.0,
    this.isLoading = false,
    this.error,
  });

  /// Get the current chunk of words to display
  List<String> get currentChunk {
    if (words.isEmpty) return [];
    final start = currentWordIndex;
    final end = (start + wordsAtATime).clamp(0, words.length);
    return words.sublist(start, end);
  }

  /// Get context lines (words before current position)
  String get contextBefore {
    if (words.isEmpty || currentWordIndex <= 0) return '';
    final start = (currentWordIndex - 8).clamp(0, words.length);
    return words.sublist(start, currentWordIndex).join(' ');
  }

  /// Get context lines (words after current position)
  String get contextAfter {
    if (words.isEmpty) return '';
    final start = (currentWordIndex + wordsAtATime).clamp(0, words.length);
    final end = (start + 8).clamp(0, words.length);
    if (start >= words.length) return '';
    return words.sublist(start, end).join(' ');
  }

  double get progress =>
      words.isNotEmpty ? currentWordIndex / words.length : 0.0;

  int get wordsRemaining =>
      (words.length - currentWordIndex).clamp(0, words.length);

  Duration get estimatedTimeLeft =>
      AppUtils.estimateReadingTime(wordsRemaining, wpm);

  /// Find which page the current word index belongs to
  int get currentPageFromWordIndex {
    if (pageBoundaries.isEmpty) return 0;
    for (int i = pageBoundaries.length - 1; i >= 0; i--) {
      if (currentWordIndex >= pageBoundaries[i]) return i;
    }
    return 0;
  }

  ReaderState copyWith({
    List<String>? words,
    List<int>? pageBoundaries,
    int? currentWordIndex,
    bool? isPlaying,
    String? documentTitle,
    String? documentHash,
    String? documentType,
    int? currentPage,
    int? totalPages,
    int? wpm,
    int? wordsAtATime,
    int? themeIndex,
    String? fontFamily,
    double? fontSize,
    bool? isLoading,
    String? error,
  }) {
    return ReaderState(
      words: words ?? this.words,
      pageBoundaries: pageBoundaries ?? this.pageBoundaries,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      documentTitle: documentTitle ?? this.documentTitle,
      documentHash: documentHash ?? this.documentHash,
      documentType: documentType ?? this.documentType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      wpm: wpm ?? this.wpm,
      wordsAtATime: wordsAtATime ?? this.wordsAtATime,
      themeIndex: themeIndex ?? this.themeIndex,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Reader Notifier ─────────────────────────────────────────────────────────

final readerProvider =
    StateNotifierProvider<ReaderNotifier, ReaderState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final stats = ref.read(statsProvider.notifier);
  final settings = ref.watch(settingsProvider);
  return ReaderNotifier(storage, stats, settings);
});

class ReaderNotifier extends StateNotifier<ReaderState> {
  final StorageService _storage;
  final StatsNotifier _stats;
  Timer? _playTimer;
  Timer? _autoSaveTimer;
  DateTime? _sessionStart;
  int _wordsReadThisSession = 0;

  ReaderNotifier(this._storage, this._stats, AppSettings settings)
      : super(ReaderState(
          wpm: settings.wpm,
          wordsAtATime: settings.wordsAtATime,
          themeIndex: settings.themeIndex,
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize,
        ));

  /// Load plain text into the reader
  void loadText(String text, {String title = 'Pasted Text'}) {
    final words = AppUtils.tokenizeText(text);
    final hash = AppUtils.computeFileHash(
        Uint8List.fromList(utf8.encode(text)));

    // Check for existing progress
    final savedProgress = _storage.loadProgress(hash);

    state = state.copyWith(
      words: words,
      pageBoundaries: [],
      currentWordIndex: savedProgress?.wordIndex ?? 0,
      isPlaying: false,
      documentTitle: title,
      documentHash: hash,
      documentType: 'text',
      currentPage: 0,
      totalPages: 1,
      wpm: savedProgress?.lastWpm ?? state.wpm,
      wordsAtATime: savedProgress?.lastWordsAtATime ?? state.wordsAtATime,
      themeIndex: savedProgress?.lastThemeIndex ?? state.themeIndex,
      fontFamily: savedProgress?.lastFont ?? state.fontFamily,
      fontSize: savedProgress?.lastFontSize ?? state.fontSize,
      isLoading: false,
      error: null,
    );

    _startAutoSave();
  }

  /// Load PDF extracted text with page boundaries
  void loadPdfText({
    required List<String> pageTexts,
    required String title,
    required String hash,
    required int totalPages,
    String? filePath,
  }) {
    final allWords = <String>[];
    final boundaries = <int>[];

    for (final pageText in pageTexts) {
      boundaries.add(allWords.length);
      allWords.addAll(AppUtils.tokenizeText(pageText));
    }

    // Check for existing progress
    final savedProgress = _storage.loadProgress(hash);

    state = state.copyWith(
      words: allWords,
      pageBoundaries: boundaries,
      currentWordIndex: savedProgress?.wordIndex ?? 0,
      isPlaying: false,
      documentTitle: title,
      documentHash: hash,
      documentType: 'pdf',
      currentPage: savedProgress?.currentPage ?? 0,
      totalPages: totalPages,
      wpm: savedProgress?.lastWpm ?? state.wpm,
      wordsAtATime: savedProgress?.lastWordsAtATime ?? state.wordsAtATime,
      themeIndex: savedProgress?.lastThemeIndex ?? state.themeIndex,
      fontFamily: savedProgress?.lastFont ?? state.fontFamily,
      fontSize: savedProgress?.lastFontSize ?? state.fontSize,
      isLoading: false,
      error: null,
    );

    // Save initial progress with file info
    _saveProgress(filePath: filePath);
    _startAutoSave();
  }

  /// Load URL content
  Future<void> loadUrl(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch URL (${response.statusCode})',
        );
        return;
      }

      final title = AppUtils.extractTitle(response.body);
      final content = AppUtils.extractReadableContent(response.body);
      final words = AppUtils.tokenizeText(content);

      if (words.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No readable content found on this page.',
        );
        return;
      }

      final hash = AppUtils.computeFileHash(
          Uint8List.fromList(utf8.encode(url)));

      final savedProgress = _storage.loadProgress(hash);

      state = state.copyWith(
        words: words,
        pageBoundaries: [],
        currentWordIndex: savedProgress?.wordIndex ?? 0,
        isPlaying: false,
        documentTitle: title,
        documentHash: hash,
        documentType: 'url',
        currentPage: 0,
        totalPages: 1,
        isLoading: false,
        error: null,
      );

      _saveProgress(sourceUrl: url);
      _startAutoSave();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load URL: $e',
      );
    }
  }

  // ─── Playback Controls ──────────────────────────────────────────────

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (state.words.isEmpty) return;
    if (state.currentWordIndex >= state.words.length) {
      // Restart from beginning
      state = state.copyWith(currentWordIndex: 0);
    }
    state = state.copyWith(isPlaying: true);
    _sessionStart ??= DateTime.now();
    _scheduleNextWord();
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
    _playTimer?.cancel();
    _saveProgress();

    // Track session time
    if (_sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      _stats.addReadingTime(elapsed);
      _sessionStart = DateTime.now();
    }

    // Track words read
    if (_wordsReadThisSession > 0) {
      _stats.addWordsRead(_wordsReadThisSession);
      _wordsReadThisSession = 0;
    }
  }

  void _scheduleNextWord() {
    _playTimer?.cancel();
    if (!state.isPlaying || state.currentWordIndex >= state.words.length) {
      if (state.currentWordIndex >= state.words.length) {
        pause();
        _stats.completeSession();
      }
      return;
    }

    // Calculate delay based on WPM + punctuation
    final baseDelay = 60000.0 / state.wpm; // ms per word
    final currentWord = state.words[state.currentWordIndex];
    final multiplier = AppUtils.punctuationDelay(currentWord);
    final delay = (baseDelay * multiplier).round();

    _playTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final nextIndex = (state.currentWordIndex + state.wordsAtATime)
          .clamp(0, state.words.length);
      _wordsReadThisSession += state.wordsAtATime;

      state = state.copyWith(
        currentWordIndex: nextIndex,
        currentPage: state.currentPageFromWordIndex,
      );

      _scheduleNextWord();
    });
  }

  /// Jump forward/back by word count
  void seekByWords(int offset) {
    final newIndex =
        (state.currentWordIndex + offset).clamp(0, state.words.length - 1);
    state = state.copyWith(
      currentWordIndex: newIndex,
      currentPage: state.currentPageFromWordIndex,
    );
    if (state.isPlaying) {
      _playTimer?.cancel();
      _scheduleNextWord();
    }
  }

  /// Jump by seconds (approximate)
  void seekByTime(int seconds) {
    final wordsToSkip = (state.wpm / 60 * seconds).round();
    seekByWords(wordsToSkip);
  }

  /// Go to specific page (PDF)
  void goToPage(int page) {
    if (page < 0 || page >= state.pageBoundaries.length) return;
    state = state.copyWith(
      currentWordIndex: state.pageBoundaries[page],
      currentPage: page,
    );
    if (state.isPlaying) {
      _playTimer?.cancel();
      _scheduleNextWord();
    }
  }

  /// Next page
  void nextPage() {
    if (state.pageBoundaries.isEmpty) return;
    final next = state.currentPageFromWordIndex + 1;
    if (next < state.pageBoundaries.length) goToPage(next);
  }

  /// Previous page
  void prevPage() {
    if (state.pageBoundaries.isEmpty) return;
    final prev = state.currentPageFromWordIndex - 1;
    if (prev >= 0) goToPage(prev);
  }

  // ─── Settings Changes (per-session) ────────────────────────────────

  void setWpm(int wpm) {
    state = state.copyWith(
        wpm: wpm.clamp(AppConstants.minWpm, AppConstants.maxWpm));
    if (state.isPlaying) {
      _playTimer?.cancel();
      _scheduleNextWord();
    }
  }

  void adjustWpm(int delta) {
    setWpm(state.wpm + delta);
  }

  void setWordsAtATime(int n) {
    state = state.copyWith(
        wordsAtATime:
            n.clamp(AppConstants.minWordsAtATime, AppConstants.maxWordsAtATime));
  }

  void setThemeIndex(int index) {
    state = state.copyWith(themeIndex: index);
  }

  void setFontFamily(String font) {
    state = state.copyWith(fontFamily: font);
  }

  void setFontSize(double size) {
    state = state.copyWith(
        fontSize:
            size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize));
  }

  // ─── Progress Persistence ──────────────────────────────────────────

  void _saveProgress({String? filePath, String? sourceUrl}) {
    if (state.documentHash.isEmpty) return;
    final progress = ReadingProgress(
      documentHash: state.documentHash,
      documentTitle: state.documentTitle,
      filePath: filePath,
      currentPage: state.currentPageFromWordIndex,
      totalPages: state.totalPages,
      wordIndex: state.currentWordIndex,
      totalWords: state.words.length,
      lastWpm: state.wpm,
      lastWordsAtATime: state.wordsAtATime,
      lastThemeIndex: state.themeIndex,
      lastFont: state.fontFamily,
      lastFontSize: state.fontSize,
      lastAccessed: DateTime.now(),
      documentType: state.documentType,
      sourceUrl: sourceUrl,
      totalReadingTimeSeconds: 0,
    );
    _storage.saveProgress(progress);
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.autoSaveIntervalSeconds),
      (_) => _saveProgress(),
    );
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _autoSaveTimer?.cancel();
    _saveProgress();
    if (_sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      _stats.addReadingTime(elapsed);
    }
    if (_wordsReadThisSession > 0) {
      _stats.addWordsRead(_wordsReadThisSession);
    }
    super.dispose();
  }
}
