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
import '../../models/reading_stats.dart';
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
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _openPdfPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Open PDF',
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      final file = result.files.single;
      if (file.path != null) {
        context.push('/pdf-reader', extra: file.path);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text?.isNotEmpty == true && mounted) {
      ref.read(readerProvider.notifier).loadText(data!.text!, title: 'Clipboard Text');
      context.push('/reader');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Clipboard is empty'),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showUrlBottomSheet() {
    _urlController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Load Web Article',
                style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
              const SizedBox(height: 6),
              const Text('Paste a URL to extract and speed-read any article',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _urlController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
                  ),
                  onSubmitted: (_) {
                    Navigator.pop(ctx);
                    _loadUrl();
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Start Reading',
                  icon: Icons.play_arrow_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    _loadUrl();
                  },
                  height: 54,
                  colors: const [AppColors.accentBlue, Color(0xFF93C5FD)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
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
      // For text documents: if the reader still has the same document loaded, resume
      final readerState = ref.read(readerProvider);
      if (readerState.documentHash == doc.documentHash && readerState.words.isNotEmpty) {
        ref.read(readerProvider.notifier).pause();
        context.push('/reader');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This document is no longer available. Please open it again.'),
            backgroundColor: AppColors.bgElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentDocs = ref.watch(recentDocumentsProvider);
    final stats = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // ── Hero Header ──
              SliverToBoxAdapter(child: _buildHeroHeader(stats)),

              // ── Action Cards ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _buildActionGrid()),
              ),

              // ── Recent Documents ──
              if (recentDocs.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded,
                            color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Text('Recent Documents',
                          style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/statistics'),
                          child: Text('See all',
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 13, fontWeight: FontWeight.w600,
                            )),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _RecentDocumentTile(
                        document: recentDocs[i],
                        onTap: () => _openRecentDocument(recentDocs[i]),
                        onRemove: () => ref
                            .read(recentDocumentsProvider.notifier)
                            .remove(recentDocs[i].documentHash),
                      ),
                      childCount: recentDocs.length,
                    ),
                  ),
                ),
              ],

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeroHeader(ReadingStats stats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0E00), AppColors.bgPrimary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentOrange, Color(0xFFFF8F5E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.4),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConstants.appName,
                    style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, letterSpacing: -0.5,
                    )),
                  Text(AppConstants.appTagline,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stats row
          Row(
            children: [
              _MiniStat(
                icon: Icons.menu_book_rounded,
                color: AppColors.accentOrange,
                value: AppUtils.formatNumber(stats.totalWordsRead),
                label: 'Words',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.timer_outlined,
                color: AppColors.accentBlue,
                value: AppUtils.formatDuration(
                    Duration(seconds: stats.totalReadingTimeSeconds)),
                label: 'Read Time',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accentYellow,
                value: '${stats.currentStreak}d',
                label: 'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Column(
      children: [
        // Primary CTA
        _PrimaryActionCard(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Open PDF',
          subtitle: 'Drag & drop or pick a file',
          gradient: const [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
          onTap: _openPdfPicker,
        ),
        const SizedBox(height: 12),

        // Secondary row
        Row(
          children: [
            Expanded(
              child: _SecondaryActionCard(
                icon: Icons.content_paste_rounded,
                label: 'Paste Text',
                subtitle: 'From clipboard',
                color: AppColors.accentPurple,
                onTap: _pasteFromClipboard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryActionCard(
                icon: Icons.language_rounded,
                label: 'Web Article',
                subtitle: 'Load a URL',
                color: AppColors.accentBlue,
                onTap: _showUrlBottomSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: true,
              onTap: () {},
            ),
            _BottomNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              isActive: false,
              onTap: () => context.push('/statistics'),
            ),
            _BottomNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isActive: false,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
                Text(label,
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PrimaryActionCard> createState() => _PrimaryActionCardState();
}

class _PrimaryActionCardState extends State<_PrimaryActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                  const SizedBox(height: 3),
                  Text(widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    )),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SecondaryActionCard> createState() => _SecondaryActionCardState();
}

class _SecondaryActionCardState extends State<_SecondaryActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
              const SizedBox(height: 3),
              Text(widget.subtitle,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accentOrange.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.accentOrange : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? AppColors.accentOrange : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
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
  bool _pressed = false;

  IconData get _typeIcon {
    switch (widget.document.documentType) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'url': return Icons.language_rounded;
      default: return Icons.text_snippet_rounded;
    }
  }

  Color get _typeColor {
    switch (widget.document.documentType) {
      case 'pdf': return AppColors.accentOrange;
      case 'url': return AppColors.accentBlue;
      default: return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final progressPct = (doc.progressPercent * 100).toStringAsFixed(0);
    final timeAgo = _formatTimeAgo(doc.lastAccessed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(doc.documentHash),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 22),
        ),
        onDismissed: (_) => widget.onRemove(),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppUtils.truncate(doc.documentTitle, 45),
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('$progressPct%',
                              style: TextStyle(
                                color: doc.progressPercent > 0.8
                                    ? AppColors.accentGreen
                                    : AppColors.textMuted,
                                fontSize: 12, fontWeight: FontWeight.w500,
                              )),
                            const Text(' · ',
                                style: TextStyle(color: AppColors.textDim)),
                            Text(timeAgo,
                              style: const TextStyle(
                                  color: AppColors.textDim, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SmoothProgressBar(
                          progress: doc.progressPercent,
                          height: 3,
                          color: _typeColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Resume badge
                  if (doc.progressPercent > 0 && doc.progressPercent < 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Resume',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        )),
                    ),
                ],
              ),
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
