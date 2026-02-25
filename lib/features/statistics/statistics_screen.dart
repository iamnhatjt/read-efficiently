import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

/// Statistics & Insights dashboard with hero stats, weekly chart,
/// and recent sessions overview.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final recentDocs = ref.watch(recentDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(context),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero Stats ──
                      _buildHeroStats(stats),
                      const SizedBox(height: 28),

                      // ── Weekly Reading Chart ──
                      _buildWeeklyChart(stats),
                      const SizedBox(height: 28),

                      // ── Documents Progress ──
                      if (recentDocs.isNotEmpty)
                        _buildDocumentsProgress(recentDocs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
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
            'Statistics & Insights',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStats(stats) {
    return Row(
      children: [
        Expanded(
          child: _HeroStatCard(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.accentOrange,
            title: 'Total Words Read',
            value: AppUtils.formatNumber(stats.totalWordsRead),
            subtitle: 'across ${stats.totalSessionsCompleted} sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HeroStatCard(
            icon: Icons.timer_outlined,
            iconColor: AppColors.accentBlue,
            title: 'Total Reading Time',
            value: AppUtils.formatDuration(
                Duration(seconds: stats.totalReadingTimeSeconds)),
            subtitle: stats.totalSessionsCompleted > 0
                ? 'avg ${AppUtils.formatDuration(Duration(seconds: stats.totalReadingTimeSeconds ~/ (stats.totalSessionsCompleted > 0 ? stats.totalSessionsCompleted : 1)))}/session'
                : 'Start reading!',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HeroStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accentYellow,
            title: 'Current Streak',
            value: '${stats.currentStreak} days',
            subtitle: 'Longest: ${stats.longestStreak} days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HeroStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.accentGreen,
            title: 'Sessions',
            value: '${stats.totalSessionsCompleted}',
            subtitle: 'completed',
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(stats) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyData = <String, int>{};
    for (final day in days) {
      weeklyData[day] = stats.weeklyWords[day] ?? 0;
    }
    final maxWords =
        weeklyData.values.fold(0, (a, b) => a > b ? a : b).clamp(1, 999999);

    // Current day of week
    final todayIndex = DateTime.now().weekday - 1; // 0=Monday

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                'This Week',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${weeklyData.values.fold(0, (a, b) => a + b)} words',
                style: TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final words = weeklyData[day] ?? 0;
                final heightFraction = maxWords > 0 ? words / maxWords : 0.0;
                final isToday = index == todayIndex;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Word count label
                        if (words > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$words',
                              style: TextStyle(
                                color: isToday
                                    ? AppColors.accentOrange
                                    : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: (heightFraction * 130).clamp(4.0, 130.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [
                                      AppColors.accentOrange,
                                      AppColors.accentOrangeLight,
                                    ]
                                  : [
                                      AppColors.accentOrange.withValues(alpha: 0.4),
                                      AppColors.accentOrange.withValues(alpha: 0.2),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day label
                        Text(
                          day,
                          style: TextStyle(
                            color: isToday
                                ? AppColors.accentOrange
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsProgress(List recentDocs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_rounded,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              'Documents Progress',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentDocs.take(8).map((doc) {
          final pct = (doc.progressPercent * 100).toStringAsFixed(0);
          return _DocumentProgressTile(doc: doc, pct: pct);
        }),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _HeroStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _HeroStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentProgressTile extends StatefulWidget {
  final dynamic doc;
  final String pct;

  const _DocumentProgressTile({required this.doc, required this.pct});

  @override
  State<_DocumentProgressTile> createState() => _DocumentProgressTileState();
}

class _DocumentProgressTileState extends State<_DocumentProgressTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;

    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (doc.documentType) {
      case 'pdf':
        typeIcon = Icons.picture_as_pdf_rounded;
        typeColor = AppColors.accentOrange;
        typeLabel = 'PDF';
        break;
      case 'url':
        typeIcon = Icons.language_rounded;
        typeColor = AppColors.accentBlue;
        typeLabel = 'URL';
        break;
      default:
        typeIcon = Icons.text_snippet_rounded;
        typeColor = AppColors.accentPurple;
        typeLabel = 'Text';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: typeColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doc.documentTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SmoothProgressBar(
                          progress: doc.progressPercent,
                          height: 3,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.pct}%',
                        style: TextStyle(
                          color: doc.progressPercent > 0.8
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
