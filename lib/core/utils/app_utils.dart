import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Utility functions for text processing, hashing, and formatting
class AppUtils {
  /// Compute SHA-256 hash of file bytes
  static String computeFileHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Split text into words, preserving whitespace knowledge
  static List<String> tokenizeText(String text) {
    // Split on whitespace, filter out empty strings
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Format duration to human-readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Estimate reading time from word count and WPM
  static Duration estimateReadingTime(int wordCount, int wpm) {
    if (wpm <= 0) return Duration.zero;
    final seconds = (wordCount / wpm * 60).round();
    return Duration(seconds: seconds);
  }

  /// Format large numbers with comma separators
  static String formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Calculate focal letter index for a word (ORP - Optimal Recognition Point)
  /// This is the letter the eye should fixate on for fastest recognition
  static int focalLetterIndex(String word) {
    final len = word.length;
    if (len <= 1) return 0;
    if (len <= 3) return 0;
    if (len <= 5) return 1;
    if (len <= 9) return 2;
    if (len <= 13) return 3;
    return 4;
  }

  /// Calculate delay multiplier for punctuation
  /// Commas get a slight pause, periods/semicolons get more
  static double punctuationDelay(String word) {
    if (word.endsWith('.') ||
        word.endsWith('!') ||
        word.endsWith('?') ||
        word.endsWith(':')) {
      return 2.0;
    }
    if (word.endsWith(',') || word.endsWith(';')) {
      return 1.5;
    }
    if (word.endsWith('"') || word.endsWith("'") || word.endsWith(')')) {
      return 1.3;
    }
    return 1.0;
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Extract file name from path
  static String fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }

  /// Simple readability extraction from HTML
  /// Extracts main text content, stripping scripts/styles/nav
  static String extractReadableContent(String htmlContent) {
    // Remove scripts and styles
    var clean = htmlContent
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<nav[^>]*>[\s\S]*?</nav>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<header[^>]*>[\s\S]*?</header>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<footer[^>]*>[\s\S]*?</footer>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<aside[^>]*>[\s\S]*?</aside>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // Replace block elements with newlines
    clean = clean
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'</div>'), '\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n\n')
        .replaceAll(RegExp(r'</li>'), '\n');

    // Strip remaining tags
    clean = clean.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode HTML entities
    clean = clean
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Clean up whitespace
    clean = clean
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return clean;
  }

  /// Extract title from HTML
  static String extractTitle(String htmlContent) {
    final titleMatch = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(htmlContent);
    if (titleMatch != null) {
      return titleMatch.group(1)?.trim() ?? 'Web Article';
    }
    // Try h1
    final h1Match = RegExp(
      r'<h1[^>]*>(.*?)</h1>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(htmlContent);
    if (h1Match != null) {
      return h1Match.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? 'Web Article';
    }
    return 'Web Article';
  }
}
