import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VibeRead color schemes — 12 beautiful reading themes
class AppColors {
  // ── Primary dark theme (default) ──
  static const Color bgPrimary = Color(0xFF0D0D0D);
  static const Color bgSecondary = Color(0xFF1A1A1A);
  static const Color bgTertiary = Color(0xFF252525);
  static const Color bgCard = Color(0xFF1E1E1E);
  static const Color bgElevated = Color(0xFF2A2A2A);

  // ── Accent colors ──
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentOrangeLight = Color(0xFFFF8F5E);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentRed = Color(0xFFF87171);
  static const Color accentYellow = Color(0xFFFBBF24);

  // ── Text colors ──
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDim = Color(0xFF4B5563);

  // ── Status ──
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Borders ──
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF444444);

  // ── Glassmorphism ──
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}

/// Reading color schemes stored as named presets
class ReadingTheme {
  final String name;
  final Color background;
  final Color text;
  final Color focalWord;
  final Color contextText;
  final Color progressBar;

  const ReadingTheme({
    required this.name,
    required this.background,
    required this.text,
    required this.focalWord,
    required this.contextText,
    required this.progressBar,
  });
}

/// 12 built-in reading themes
const List<ReadingTheme> kReadingThemes = [
  ReadingTheme(
    name: 'Midnight',
    background: Color(0xFF0D0D0D),
    text: Color(0xFFF5F5F5),
    focalWord: Color(0xFFFF6B35),
    contextText: Color(0xFF6B7280),
    progressBar: Color(0xFFFF6B35),
  ),
  ReadingTheme(
    name: 'Deep Ocean',
    background: Color(0xFF0A1628),
    text: Color(0xFFE2E8F0),
    focalWord: Color(0xFF38BDF8),
    contextText: Color(0xFF475569),
    progressBar: Color(0xFF38BDF8),
  ),
  ReadingTheme(
    name: 'Forest',
    background: Color(0xFF0B1A0B),
    text: Color(0xFFD1FAE5),
    focalWord: Color(0xFF4ADE80),
    contextText: Color(0xFF3B5249),
    progressBar: Color(0xFF4ADE80),
  ),
  ReadingTheme(
    name: 'Warm Sepia',
    background: Color(0xFF1C1610),
    text: Color(0xFFE8D5B7),
    focalWord: Color(0xFFD4A373),
    contextText: Color(0xFF6B5B4E),
    progressBar: Color(0xFFD4A373),
  ),
  ReadingTheme(
    name: 'Purple Haze',
    background: Color(0xFF150D1E),
    text: Color(0xFFE9D5FF),
    focalWord: Color(0xFFA855F7),
    contextText: Color(0xFF5B4174),
    progressBar: Color(0xFFA855F7),
  ),
  ReadingTheme(
    name: 'Crimson Night',
    background: Color(0xFF1A0A0A),
    text: Color(0xFFFECACA),
    focalWord: Color(0xFFF87171),
    contextText: Color(0xFF6B3030),
    progressBar: Color(0xFFF87171),
  ),
  ReadingTheme(
    name: 'Amber Glow',
    background: Color(0xFF1A1400),
    text: Color(0xFFFEF3C7),
    focalWord: Color(0xFFFBBF24),
    contextText: Color(0xFF6B5E1A),
    progressBar: Color(0xFFFBBF24),
  ),
  ReadingTheme(
    name: 'Slate',
    background: Color(0xFF1E293B),
    text: Color(0xFFCBD5E1),
    focalWord: Color(0xFF94A3B8),
    contextText: Color(0xFF475569),
    progressBar: Color(0xFF94A3B8),
  ),
  ReadingTheme(
    name: 'Paper White',
    background: Color(0xFFF8F6F0),
    text: Color(0xFF1A1A1A),
    focalWord: Color(0xFFDC2626),
    contextText: Color(0xFF9CA3AF),
    progressBar: Color(0xFFDC2626),
  ),
  ReadingTheme(
    name: 'Cream',
    background: Color(0xFFF5F0E8),
    text: Color(0xFF2D2A24),
    focalWord: Color(0xFF92400E),
    contextText: Color(0xFFA8A29E),
    progressBar: Color(0xFF92400E),
  ),
  ReadingTheme(
    name: 'Terminal',
    background: Color(0xFF0A0A0A),
    text: Color(0xFF00FF41),
    focalWord: Color(0xFFFFFFFF),
    contextText: Color(0xFF006B1A),
    progressBar: Color(0xFF00FF41),
  ),
  ReadingTheme(
    name: 'Nord',
    background: Color(0xFF2E3440),
    text: Color(0xFFD8DEE9),
    focalWord: Color(0xFF88C0D0),
    contextText: Color(0xFF4C566A),
    progressBar: Color(0xFF88C0D0),
  ),
];

/// Main app theme builder
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentOrange,
        secondary: AppColors.accentOrangeLight,
        surface: AppColors.bgSecondary,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -1.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentOrange,
        inactiveTrackColor: AppColors.bgTertiary,
        thumbColor: AppColors.accentOrange,
        overlayColor: AppColors.accentOrange.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
