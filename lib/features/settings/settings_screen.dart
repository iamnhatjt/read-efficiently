import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';


/// Settings screen with tabbed layout:
/// Interface / Reading / Themes / Data
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Interface', 'Reading', 'Themes', 'Data'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InterfaceTab(),
                _ReadingTab(),
                _ThemesTab(),
                _DataTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.accentOrange,
                      AppColors.accentOrangeLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.accentOrange,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.accentOrange,
            indicatorSize: TabBarIndicatorSize.label,
            dividerHeight: 0,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Interface Tab ───────────────────────────────────────────────────────────

class _InterfaceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Window section ──
              _SectionCard(
                title: 'Window',
                icon: Icons.desktop_windows_rounded,
                children: [
                  _ToggleRow(
                    label: 'Always on Top',
                    subtitle: 'Keep VibeRead above other windows',
                    value: settings.alwaysOnTop,
                    onChanged: (_) => notifier.toggleAlwaysOnTop(),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _ToggleRow(
                    label: 'Focus Mode',
                    subtitle: 'Hide UI elements while reading',
                    value: settings.focusMode,
                    onChanged: (_) => notifier.toggleFocusMode(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Font section ──
              _SectionCard(
                title: 'Font',
                icon: Icons.text_fields_rounded,
                children: [
                  const Text(
                    'Reading Font',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.readingFonts.map((font) {
                      final isActive = settings.fontFamily == font;
                      return GestureDetector(
                        onTap: () => notifier.setFontFamily(font),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.accentOrange
                                      .withValues(alpha: 0.15)
                                  : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.accentOrange
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.accentOrange
                                    : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Font Size',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${settings.fontSize.round()}px',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Expanded(
                        child: Slider(
                          value: settings.fontSize,
                          min: AppConstants.minFontSize,
                          max: AppConstants.maxFontSize,
                          divisions: ((AppConstants.maxFontSize -
                                      AppConstants.minFontSize) /
                                  4)
                              .round(),
                          onChanged: (v) => notifier.setFontSize(v),
                        ),
                      ),
                    ],
                  ),
                  // Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        'The quick brown fox',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize:
                              settings.fontSize.clamp(16, 42).toDouble(),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Display section ──
              _SectionCard(
                title: 'Display',
                icon: Icons.visibility_rounded,
                children: [
                  _ToggleRow(
                    label: 'Context Lines',
                    subtitle: 'Show words before/after the focal word',
                    value: settings.showContextLines,
                    onChanged: (_) => notifier.toggleContextLines(),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _ToggleRow(
                    label: 'Auto Page Turn',
                    subtitle: 'Automatically advance pages in PDFs',
                    value: settings.autoPageTurn,
                    onChanged: (_) => notifier.toggleAutoPageTurn(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reading Tab ─────────────────────────────────────────────────────────────

class _ReadingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Speed section ──
              _SectionCard(
                title: 'Speed',
                icon: Icons.speed_rounded,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Default WPM',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${settings.wpm} WPM',
                          style: const TextStyle(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.wpm.toDouble(),
                    min: AppConstants.minWpm.toDouble(),
                    max: AppConstants.maxWpm.toDouble(),
                    divisions: (AppConstants.maxWpm - AppConstants.minWpm) ~/
                        AppConstants.wpmStep,
                    onChanged: (v) => notifier.setWpm(v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppConstants.minWpm}',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 11)),
                      Text('${AppConstants.maxWpm}',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Words at a Time',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final n = i + 1;
                      final isActive = settings.wordsAtATime == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => notifier.setWordsAtATime(n),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.accentOrange
                                        .withValues(alpha: 0.2)
                                    : AppColors.bgTertiary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.accentOrange
                                      : AppColors.border,
                                  width: isActive ? 1.5 : 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$n',
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.accentOrange
                                        : AppColors.textSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── TTS section ──
              _SectionCard(
                title: 'Text-to-Speech',
                icon: Icons.volume_up_rounded,
                children: [
                  _ToggleRow(
                    label: 'Enable TTS',
                    subtitle: 'Read along with text-to-speech',
                    value: settings.ttsEnabled,
                    onChanged: (_) => notifier.toggleTts(),
                  ),
                  if (settings.ttsEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Speed',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${settings.ttsSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.ttsSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      onChanged: (v) => notifier.setTtsSpeed(v),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Themes Tab ──────────────────────────────────────────────────────────────

class _ThemesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Color Schemes',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose your perfect reading environment',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Theme grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: kReadingThemes.length,
                itemBuilder: (context, index) {
                  final theme = kReadingThemes[index];
                  final isActive = settings.themeIndex == index;

                  return _ThemePreviewCard(
                    theme: theme,
                    isActive: isActive,
                    onTap: () => notifier.setThemeIndex(index),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatefulWidget {
  final ReadingTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<_ThemePreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isActive
                  ? widget.theme.focalWord
                  : (_hovered ? AppColors.borderLight : AppColors.border),
              width: widget.isActive ? 2 : 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              children: [
                // Theme preview area
                Expanded(
                  child: Container(
                    color: widget.theme.background,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'fo',
                            style: TextStyle(
                              color: widget.theme.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'c',
                            style: TextStyle(
                              color: widget.theme.focalWord,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'us',
                            style: TextStyle(
                              color: widget.theme.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Theme name bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: AppColors.bgCard,
                  child: Row(
                    children: [
                      Text(
                        widget.theme.name,
                        style: TextStyle(
                          color: widget.isActive
                              ? widget.theme.focalWord
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (widget.isActive)
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: widget.theme.focalWord,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data Tab ────────────────────────────────────────────────────────────────

class _DataTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Export & Import',
                icon: Icons.save_alt_rounded,
                children: [
                  const Text(
                    'Export all your reading progress, settings, and statistics to a JSON file for backup.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportData(context, ref),
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('Export Progress (JSON)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _importData(context, ref),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Import Progress'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionCard(
                title: 'Danger Zone',
                icon: Icons.warning_amber_rounded,
                borderColor: AppColors.error.withValues(alpha: 0.3),
                children: [
                  const Text(
                    'Permanently delete all reading progress, settings, and statistics. This cannot be undone.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmClearAll(context, ref),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Clear All Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final json = storage.exportAllData();

      // Copy to clipboard and show in dialog
      await Clipboard.setData(ClipboardData(text: json));

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgSecondary,
            title: const Text('Data Exported',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your data has been copied to clipboard. Save it as a .json file for backup.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      json.length > 500 ? '${json.substring(0, 500)}...' : json,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) return;

      final json = utf8.decode(fileBytes);

      final storage = ref.read(storageServiceProvider);
      await storage.importData(json);

      // Refresh providers
      ref.read(recentDocumentsProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress imported successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Clear All Data?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will delete all your reading progress, settings, and statistics. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(storageServiceProvider).clearAll();
              ref.read(recentDocumentsProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared.'),
                    backgroundColor: AppColors.bgElevated,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Everything',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Tab Widgets ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accentOrange,
          inactiveTrackColor: AppColors.bgTertiary,
        ),
      ],
    );
  }
}
