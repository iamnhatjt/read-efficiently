import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

/// Main RSVP (Rapid Serial Visual Presentation) reader screen.
/// Cinema-like, distraction-free reading experience with focal word 
/// highlighting, playback controls, and keyboard shortcuts.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _showControls = false;
  bool _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Auto-focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final reader = ref.read(readerProvider.notifier);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        reader.togglePlay();
        break;
      case LogicalKeyboardKey.keyJ:
        reader.seekByTime(-10);
        break;
      case LogicalKeyboardKey.keyK:
        reader.togglePlay();
        break;
      case LogicalKeyboardKey.keyL:
        reader.seekByTime(10);
        break;
      case LogicalKeyboardKey.arrowUp:
        reader.adjustWpm(AppConstants.wpmStep);
        break;
      case LogicalKeyboardKey.arrowDown:
        reader.adjustWpm(-AppConstants.wpmStep);
        break;
      case LogicalKeyboardKey.arrowLeft:
        if (ref.read(readerProvider).documentType == 'pdf') {
          reader.prevPage();
        } else {
          reader.seekByWords(-1);
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (ref.read(readerProvider).documentType == 'pdf') {
          reader.nextPage();
        } else {
          reader.seekByWords(1);
        }
        break;
      case LogicalKeyboardKey.digit1:
        reader.setWordsAtATime(1);
        break;
      case LogicalKeyboardKey.digit2:
        reader.setWordsAtATime(2);
        break;
      case LogicalKeyboardKey.digit3:
        reader.setWordsAtATime(3);
        break;
      case LogicalKeyboardKey.digit4:
        reader.setWordsAtATime(4);
        break;
      case LogicalKeyboardKey.digit5:
        reader.setWordsAtATime(5);
        break;
      case LogicalKeyboardKey.escape:
        if (mounted) context.go('/');
        break;
      case LogicalKeyboardKey.keyH:
        setState(() => _showControls = !_showControls);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider);
    final theme = kReadingThemes[
        readerState.themeIndex.clamp(0, kReadingThemes.length - 1)];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: theme.background,
        body: readerState.isLoading
            ? _buildLoading(theme)
            : readerState.error != null
                ? _buildError(theme, readerState.error!)
                : readerState.words.isEmpty
                    ? _buildEmpty(theme)
                    : _buildReader(readerState, theme),
      ),
    );
  }

  Widget _buildLoading(ReadingTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.focalWord),
          const SizedBox(height: 16),
          Text('Loading...', style: TextStyle(color: theme.text)),
        ],
      ),
    );
  }

  Widget _buildError(ReadingTheme theme, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(error,
              style: TextStyle(color: theme.text, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ReadingTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.text_snippet_outlined, color: theme.contextText, size: 48),
          const SizedBox(height: 16),
          Text('No content loaded',
              style: TextStyle(color: theme.text, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Go back and paste text or open a document',
              style: TextStyle(color: theme.contextText)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildReader(ReaderState state, ReadingTheme theme) {
    final settings = ref.watch(settingsProvider);
    final reader = ref.read(readerProvider.notifier);

    // Auto-hide controls when playing, show when paused
    final shouldShowControls = !state.isPlaying;
    if (_showControls != shouldShowControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showControls = shouldShowControls);
      });
    }

    return Stack(
      children: [
        // ── Main gesture + content area ──
        GestureDetector(
          onTap: () => reader.togglePlay(),
          // Swipe left/right → seek words
          // Swipe up/down   → adjust WPM
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx.abs() > 200) {
              if (dx < 0) reader.seekByWords(1);
              else reader.seekByWords(-1);
            }
          },
          onVerticalDragEnd: (details) {
            final dy = details.primaryVelocity ?? 0;
            if (dy.abs() > 200) {
              if (dy < 0) reader.adjustWpm(AppConstants.wpmStep);
              else reader.adjustWpm(-AppConstants.wpmStep);
            }
          },
          child: Column(
            children: [
              // ── Top bar (animated) ──
              AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: _buildTopBar(state, theme),
                ),
              ),

              // ── Focal reading area (center) ──
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.showContextLines)
                          Text(
                            state.contextBefore,
                            style: TextStyle(
                              color: theme.contextText,
                              fontSize: 15,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (settings.showContextLines) const SizedBox(height: 16),

                        // ── FOCAL WORD(S) — the hero ──
                        _buildFocalWord(state, theme),

                        if (settings.showContextLines) const SizedBox(height: 16),
                        if (settings.showContextLines)
                          Text(
                            state.contextAfter,
                            style: TextStyle(
                              color: theme.contextText,
                              fontSize: 15,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        // ── Swipe hint (shown when controls hidden) ──
                        if (!_showControls) ...[
                          const SizedBox(height: 40),
                          AnimatedOpacity(
                            opacity: !_showControls ? 0.35 : 0.0,
                            duration: const Duration(milliseconds: 400),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swipe_rounded,
                                    color: theme.contextText, size: 14),
                                const SizedBox(width: 6),
                                Text('Swipe ←→ to seek · ↑↓ WPM',
                                  style: TextStyle(
                                      color: theme.contextText, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Progress bar ──
              SmoothProgressBar(
                progress: state.progress,
                color: theme.progressBar,
                height: 3,
                backgroundColor: theme.background == const Color(0xFF0D0D0D)
                    ? AppColors.bgTertiary
                    : theme.contextText.withValues(alpha: 0.2),
              ),

              // ── Bottom controls (animated) ──
              AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: _buildBottomControls(state, theme),
                ),
              ),
            ],
          ),
        ),

        // ── Inline settings panel ──
        if (_settingsOpen) _buildSettingsPanel(state, theme),
      ],
    );
  }

  /// Builds the focal word display with ORP (Optimal Recognition Point) highlighting
  Widget _buildFocalWord(ReaderState state, ReadingTheme theme) {
    final chunk = state.currentChunk;
    if (chunk.isEmpty) return const SizedBox();

    final fontFamily = _resolveFont(state.fontFamily);

    if (chunk.length == 1) {
      // Single word — apply ORP highlighting
      final word = chunk[0];
      final focalIndex = AppUtils.focalLetterIndex(word);

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left part (before focal)
          if (focalIndex > 0)
            Text(
              word.substring(0, focalIndex),
              style: TextStyle(
                color: theme.text,
                fontSize: state.fontSize,
                fontFamily: fontFamily,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          // Focal letter (highlighted)
          Text(
            focalIndex < word.length
                ? word[focalIndex]
                : '',
            style: TextStyle(
              color: theme.focalWord,
              fontSize: state.fontSize,
              fontFamily: fontFamily,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          // Right part (after focal)
          if (focalIndex + 1 < word.length)
            Text(
              word.substring(focalIndex + 1),
              style: TextStyle(
                color: theme.text,
                fontSize: state.fontSize,
                fontFamily: fontFamily,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
        ],
      );
    } else {
      // Multiple words — highlight the focal word in the chunk
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: chunk.asMap().entries.map((entry) {
          final isFocal = entry.key == 0;
          return Text(
            entry.value,
            style: TextStyle(
              color: isFocal ? theme.focalWord : theme.text,
              fontSize: state.fontSize,
              fontFamily: fontFamily,
              fontWeight: isFocal ? FontWeight.w800 : FontWeight.w400,
              height: 1.2,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildTopBar(ReaderState state, ReadingTheme theme) {
    final pageInfo = state.documentType == 'pdf'
        ? ' — Page ${state.currentPageFromWordIndex + 1} of ${state.totalPages}'
        : '';

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: theme.background.withValues(alpha: 0.9),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                ref.read(readerProvider.notifier).pause();
                context.go('/');
              },
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: theme.contextText, size: 18),
            ),
            const SizedBox(width: 12),

            // Document title
            Expanded(
              child: Text(
                '${state.documentTitle}$pageInfo',
                style: TextStyle(
                  color: theme.text.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Time remaining
            Text(
              '~${AppUtils.formatDuration(state.estimatedTimeLeft)} left',
              style: TextStyle(color: theme.contextText, fontSize: 13),
            ),
            const SizedBox(width: 20),

            // WPM display with arrows
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => ref
                      .read(readerProvider.notifier)
                      .adjustWpm(-AppConstants.wpmStep),
                  child: Icon(Icons.remove, color: theme.contextText, size: 14),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.focalWord.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.focalWord.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${state.wpm} WPM',
                    style: TextStyle(
                      color: theme.focalWord,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => ref
                      .read(readerProvider.notifier)
                      .adjustWpm(AppConstants.wpmStep),
                  child: Icon(Icons.add, color: theme.contextText, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ReaderState state, ReadingTheme theme) {
    final reader = ref.read(readerProvider.notifier);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WPM pill row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => reader.adjustWpm(-AppConstants.wpmStep),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: theme.focalWord.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove_rounded,
                        color: theme.focalWord, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.focalWord.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.focalWord.withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: Text(
                    '${state.wpm} WPM',
                    style: TextStyle(
                      color: theme.focalWord,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => reader.adjustWpm(AppConstants.wpmStep),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: theme.focalWord.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded,
                        color: theme.focalWord, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Page navigation row (PDF only)
            if (state.documentType == 'pdf' && state.totalPages > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => reader.prevPage(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: theme.contextText.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_left_rounded,
                          color: theme.contextText, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showPageJumpDialog(state, theme, reader),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.contextText.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.contextText.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Page ${state.currentPageFromWordIndex + 1} / ${state.totalPages}',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => reader.nextPage(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: theme.contextText.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          color: theme.contextText, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Main controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.fast_rewind_rounded,
                  label: '-10s',
                  onTap: () => reader.seekByTime(-10),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  label: 'Prev',
                  onTap: () => reader.seekByWords(-1),
                  theme: theme,
                ),
                const SizedBox(width: 16),

                // Play/Pause — hero button (larger)
                GestureDetector(
                  onTap: () => reader.togglePlay(),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [theme.focalWord,
                            theme.focalWord.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.focalWord.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Next',
                  onTap: () => reader.seekByWords(1),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.fast_forward_rounded,
                  label: '+10s',
                  onTap: () => reader.seekByTime(10),
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Settings + Close row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () => setState(() => _settingsOpen = !_settingsOpen),
                  theme: theme,
                  isActive: _settingsOpen,
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: Icons.close_rounded,
                  label: 'Exit',
                  onTap: () {
                    reader.pause();
                    context.go('/');
                  },
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPageJumpDialog(ReaderState state, ReadingTheme theme, ReaderNotifier reader) {
    final controller = TextEditingController(
      text: '${state.currentPageFromWordIndex + 1}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Jump to Page',
          style: TextStyle(color: theme.text, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a page number (1 – ${state.totalPages})',
              style: TextStyle(color: theme.contextText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: theme.text, fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.contextText.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.contextText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.focalWord, width: 2),
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= state.totalPages) {
                  reader.goToPage(page - 1);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.contextText)),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= state.totalPages) {
                reader.goToPage(page - 1);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.focalWord,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Inline settings panel (overlaid)
  Widget _buildSettingsPanel(ReaderState state, ReadingTheme theme) {
    final reader = ref.read(readerProvider.notifier);

    return Positioned(
      right: 16,
      bottom: 80,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Reading Settings',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _settingsOpen = false),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // WPM slider
            _SettingsRow(
              label: 'Speed',
              value: '${state.wpm} WPM',
              child: Slider(
                value: state.wpm.toDouble(),
                min: AppConstants.minWpm.toDouble(),
                max: AppConstants.maxWpm.toDouble(),
                divisions: (AppConstants.maxWpm - AppConstants.minWpm) ~/
                    AppConstants.wpmStep,
                onChanged: (v) => reader.setWpm(v.round()),
              ),
            ),
            const SizedBox(height: 12),

            // Words at a time
            _SettingsRow(
              label: 'Words at a time',
              value: '${state.wordsAtATime}',
              child: Row(
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final isActive = state.wordsAtATime == n;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => reader.setWordsAtATime(n),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.focalWord.withValues(alpha: 0.2)
                                : AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? theme.focalWord
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$n',
                              style: TextStyle(
                                color: isActive
                                    ? theme.focalWord
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Font size slider
            _SettingsRow(
              label: 'Font Size',
              value: '${state.fontSize.round()}px',
              child: Slider(
                value: state.fontSize,
                min: AppConstants.minFontSize,
                max: AppConstants.maxFontSize,
                divisions: ((AppConstants.maxFontSize - AppConstants.minFontSize) / 4).round(),
                onChanged: (v) => reader.setFontSize(v),
              ),
            ),
            const SizedBox(height: 12),

            // Theme selector (compact)
            const Text(
              'Color Scheme',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kReadingThemes.asMap().entries.map((entry) {
                final isActive = state.themeIndex == entry.key;
                return GestureDetector(
                  onTap: () => reader.setThemeIndex(entry.key),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: entry.value.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isActive
                              ? entry.value.focalWord
                              : AppColors.border,
                          width: isActive ? 2 : 0.5,
                        ),
                      ),
                      child: isActive
                          ? Icon(Icons.check,
                              size: 14, color: entry.value.focalWord)
                          : Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: entry.value.focalWord,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Keyboard shortcuts hint
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shortcuts',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Space: Play/Pause · ↑↓: WPM · 1-5: Words\nJ/L: ±10s · ←→: Prev/Next · H: Hide UI',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resolve font name to the appropriate font family for GoogleFonts
  String _resolveFont(String fontName) {
    try {
      switch (fontName) {
        case 'Georgia':
          return 'Georgia';
        case 'Literata':
          return GoogleFonts.literata().fontFamily ?? fontName;
        case 'Merriweather':
          return GoogleFonts.merriweather().fontFamily ?? fontName;
        case 'Lora':
          return GoogleFonts.lora().fontFamily ?? fontName;
        case 'Roboto Slab':
          return GoogleFonts.robotoSlab().fontFamily ?? fontName;
        case 'Source Serif 4':
          return GoogleFonts.sourceSerif4().fontFamily ?? fontName;
        case 'Noto Serif':
          return GoogleFonts.notoSerif().fontFamily ?? fontName;
        case 'IBM Plex Serif':
          return GoogleFonts.ibmPlexSerif().fontFamily ?? fontName;
        case 'Crimson Text':
          return GoogleFonts.crimsonText().fontFamily ?? fontName;
        default:
          return GoogleFonts.inter().fontFamily ?? fontName;
      }
    } catch (_) {
      return fontName;
    }
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ReadingTheme theme;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    this.isActive = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isActive || _hovered
                    ? AppColors.glassWhite
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isActive
                    ? widget.theme.focalWord
                    : (_hovered
                        ? AppColors.textPrimary
                        : AppColors.textSecondary),
              ),
            ),
            if (widget.label.isNotEmpty)
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
