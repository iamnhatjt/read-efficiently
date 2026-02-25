import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/reading_progress.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _urlController = TextEditingController();
  bool _showUrlInput = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _openPdfPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Open PDF',
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      final path = result.files.single.path;
      if (path != null) {
        context.push('/pdf-reader', extra: path);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty && mounted) {
      ref.read(readerProvider.notifier).loadText(data.text!, title: 'Clipboard Text');
      context.push('/reader');
    }
  }

  void _loadUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    // Ensure URL has scheme
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    ref.read(readerProvider.notifier).loadUrl(fullUrl);
    context.push('/reader');
  }

  void _openRecentDocument(ReadingProgress doc) {
    if (doc.documentType == 'pdf' && doc.filePath != null) {
      context.push('/pdf-reader', extra: doc.filePath);
    } else if (doc.documentType == 'url' && doc.sourceUrl != null) {
      ref.read(readerProvider.notifier).loadUrl(doc.sourceUrl!);
      context.push('/reader');
    } else {
      // Text documents — can't re-open without content
      // Show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text documents are session-only. Paste text again to continue.'),
          backgroundColor: AppColors.bgElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentDocs = ref.watch(recentDocumentsProvider);
    final stats = ref.watch(statsProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo & Header ──
                    _buildHeader(),
                    const SizedBox(height: 48),

                    // ── Quick Stats ──
                    _buildQuickStats(stats),
                    const SizedBox(height: 40),

                    // ── Main Action Buttons ──
                    _buildActionButtons(),
                    const SizedBox(height: 16),

                    // ── URL Input (conditional) ──
                    if (_showUrlInput) ...[
                      _buildUrlInput(),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 40),

                    // ── Recent Documents ──
                    if (recentDocs.isNotEmpty) ...[
                      _buildRecentDocuments(recentDocs),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Logo icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentOrange, Color(0xFFFF8F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'v${AppConstants.appVersion}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(ReadingStats stats) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.menu_book_rounded,
          label: 'Words Read',
          value: AppUtils.formatNumber(stats.totalWordsRead),
          color: AppColors.accentOrange,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.timer_outlined,
          label: 'Reading Time',
          value: AppUtils.formatDuration(
              Duration(seconds: stats.totalReadingTimeSeconds)),
          color: AppColors.accentBlue,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: '${stats.currentStreak} days',
          color: AppColors.accentYellow,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.check_circle_outline_rounded,
          label: 'Sessions',
          value: '${stats.totalSessionsCompleted}',
          color: AppColors.accentGreen,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Hero button — Open PDF
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Open PDF Reader',
            icon: Icons.picture_as_pdf_rounded,
            onTap: _openPdfPicker,
            height: 72,
            colors: const [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
          ),
        ),
        const SizedBox(height: 16),

        // Secondary action row
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.content_paste_rounded,
                label: 'Paste Text',
                subtitle: 'From clipboard',
                onTap: _pasteFromClipboard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.language_rounded,
                label: 'Load URL',
                subtitle: 'Web article',
                onTap: () => setState(() => _showUrlInput = !_showUrlInput),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.bar_chart_rounded,
                label: 'Statistics',
                subtitle: 'Your progress',
                onTap: () => context.push('/statistics'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.settings_rounded,
                label: 'Settings',
                subtitle: 'Customize',
                onTap: () => context.push('/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrlInput() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste article URL here...',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _loadUrl(),
              ),
            ),
            const SizedBox(width: 8),
            GradientButton(
              label: 'Load',
              icon: Icons.download_rounded,
              onTap: _loadUrl,
              height: 40,
              colors: const [AppColors.accentBlue, Color(0xFF93C5FD)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocuments(List<ReadingProgress> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recent Documents',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...docs.map((doc) => _RecentDocumentTile(
              document: doc,
              onTap: () => _openRecentDocument(doc),
              onRemove: () {
                ref.read(recentDocumentsProvider.notifier).remove(doc.documentHash);
              },
            )),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgElevated : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppColors.borderLight : AppColors.border,
              width: 0.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: AppColors.textSecondary, size: 28),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocumentTile extends StatefulWidget {
  final ReadingProgress document;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentDocumentTile({
    required this.document,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_RecentDocumentTile> createState() => _RecentDocumentTileState();
}

class _RecentDocumentTileState extends State<_RecentDocumentTile> {
  bool _hovered = false;

  IconData get _typeIcon {
    switch (widget.document.documentType) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'url':
        return Icons.language_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Color get _typeColor {
    switch (widget.document.documentType) {
      case 'pdf':
        return AppColors.accentOrange;
      case 'url':
        return AppColors.accentBlue;
      default:
        return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final progressPct = (doc.progressPercent * 100).toStringAsFixed(0);
    final timeAgo = _formatTimeAgo(doc.lastAccessed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgElevated : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? AppColors.borderLight : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppUtils.truncate(doc.documentTitle, 50),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$progressPct% complete',
                            style: TextStyle(
                              color: doc.progressPercent > 0.8
                                  ? AppColors.accentGreen
                                  : AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (doc.documentType == 'pdf') ...[
                            const Text(' · ',
                                style: TextStyle(color: AppColors.textDim)),
                            Text(
                              'Page ${doc.currentPage + 1}/${doc.totalPages}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const Text(' · ',
                              style: TextStyle(color: AppColors.textDim)),
                          Text(
                            '${doc.lastWpm} WPM',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const Text(' · ',
                              style: TextStyle(color: AppColors.textDim)),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar mini
                SizedBox(
                  width: 60,
                  child: SmoothProgressBar(
                    progress: doc.progressPercent,
                    height: 3,
                    color: _typeColor,
                  ),
                ),
                const SizedBox(width: 8),

                // Resume indicator
                if (doc.progressPercent > 0 && doc.progressPercent < 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Remove button
                if (_hovered)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textDim,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
