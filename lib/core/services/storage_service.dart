import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../models/reading_progress.dart';
import '../../models/reading_stats.dart';
import '../../models/app_settings.dart';

/// Hive-based local storage service for all persistent data
class StorageService {
  late Box _progressBox;
  late Box _settingsBox;
  late Box _statsBox;
  late Box _recentBox;

  /// Initialize Hive and open all boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _progressBox = await Hive.openBox(AppConstants.hiveProgressBox);
    _settingsBox = await Hive.openBox(AppConstants.hiveSettingsBox);
    _statsBox = await Hive.openBox(AppConstants.hiveStatsBox);
    _recentBox = await Hive.openBox(AppConstants.hiveRecentBox);
  }

  // ─── Reading Progress ───────────────────────────────────────────────

  /// Save reading progress keyed by document hash
  Future<void> saveProgress(ReadingProgress progress) async {
    await _progressBox.put(
      progress.documentHash,
      jsonEncode(progress.toJson()),
    );
    // Also update recent documents
    await _addToRecent(progress);
  }

  /// Load reading progress by document hash
  ReadingProgress? loadProgress(String documentHash) {
    final data = _progressBox.get(documentHash);
    if (data == null) return null;
    try {
      return ReadingProgress.fromJson(jsonDecode(data as String));
    } catch (_) {
      return null;
    }
  }

  /// Delete reading progress
  Future<void> deleteProgress(String documentHash) async {
    await _progressBox.delete(documentHash);
  }

  /// Get all saved progress entries
  List<ReadingProgress> getAllProgress() {
    final entries = <ReadingProgress>[];
    for (final key in _progressBox.keys) {
      final data = _progressBox.get(key);
      if (data != null) {
        try {
          entries.add(ReadingProgress.fromJson(jsonDecode(data as String)));
        } catch (_) {}
      }
    }
    entries.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
    return entries;
  }

  // ─── Recent Documents ───────────────────────────────────────────────

  Future<void> _addToRecent(ReadingProgress progress) async {
    await _recentBox.put(
      progress.documentHash,
      jsonEncode(progress.toJson()),
    );
  }

  List<ReadingProgress> getRecentDocuments({int limit = 20}) {
    final entries = <ReadingProgress>[];
    for (final key in _recentBox.keys) {
      final data = _recentBox.get(key);
      if (data != null) {
        try {
          entries.add(ReadingProgress.fromJson(jsonDecode(data as String)));
        } catch (_) {}
      }
    }
    entries.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
    return entries.take(limit).toList();
  }

  Future<void> removeFromRecent(String documentHash) async {
    await _recentBox.delete(documentHash);
  }

  // ─── App Settings ──────────────────────────────────────────────────

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('settings', jsonEncode(settings.toJson()));
  }

  AppSettings loadSettings() {
    final data = _settingsBox.get('settings');
    if (data == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(data as String));
    } catch (_) {
      return const AppSettings();
    }
  }

  // ─── Reading Statistics ────────────────────────────────────────────

  Future<void> saveStats(ReadingStats stats) async {
    await _statsBox.put('stats', jsonEncode(stats.toJson()));
  }

  ReadingStats loadStats() {
    final data = _statsBox.get('stats');
    if (data == null) return ReadingStats();
    try {
      return ReadingStats.fromJson(jsonDecode(data as String));
    } catch (_) {
      return ReadingStats();
    }
  }

  // ─── Export/Import ─────────────────────────────────────────────────

  /// Export all data as JSON string
  String exportAllData() {
    final data = {
      'progress': {
        for (final key in _progressBox.keys)
          key: _progressBox.get(key),
      },
      'settings': _settingsBox.get('settings'),
      'stats': _statsBox.get('stats'),
      'recent': {
        for (final key in _recentBox.keys)
          key: _recentBox.get(key),
      },
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': AppConstants.appVersion,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import data from JSON string
  Future<void> importData(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    if (data.containsKey('progress')) {
      final progress = data['progress'] as Map<String, dynamic>;
      for (final entry in progress.entries) {
        await _progressBox.put(entry.key, entry.value);
      }
    }

    if (data.containsKey('settings')) {
      await _settingsBox.put('settings', data['settings']);
    }

    if (data.containsKey('stats')) {
      await _statsBox.put('stats', data['stats']);
    }

    if (data.containsKey('recent')) {
      final recent = data['recent'] as Map<String, dynamic>;
      for (final entry in recent.entries) {
        await _recentBox.put(entry.key, entry.value);
      }
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _progressBox.clear();
    await _settingsBox.clear();
    await _statsBox.clear();
    await _recentBox.clear();
  }
}
