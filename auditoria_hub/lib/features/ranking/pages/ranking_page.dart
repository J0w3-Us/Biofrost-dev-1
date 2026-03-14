// features/ranking/pages/ranking_page.dart — Pantalla de ranking (Biofrost v2 — Clean Podium)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../showcase/domain/models/project_read_model.dart';
import '../../showcase/providers/showcase_provider.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(showcaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort by score descending
    final sorted = [...state.projects]
      ..sort((a, b) => b.avgScore.compareTo(a.avgScore));

    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ranking',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Proyectos más destacados',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppColors.podiumGold,
              size: 26,
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const _RankingSkeletons()
          : state.projects.isEmpty
              ? const BioEmptyView(
                  title: 'Sin proyectos',
                  subtitle: 'No hay proyectos disponibles aún',
                  icon: Icons.bar_chart_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp24),
                  children: [
                    // ── Podio Limpio ────────────────────────────────────────
                    if (top3.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.sp16,
                            AppSpacing.sp20, AppSpacing.sp16, AppSpacing.sp16),
                        child: _CleanPodium(top3: top3, isDark: isDark),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16,
                            vertical: AppSpacing.sp8),
                        child: BioDivider(label: 'Clasificación'),
                      ),
                    ],

                    // ── Lista posiciones 4+ ─────────────────────────────────
                    if (rest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface1
                                : AppColors.lightCard,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha(isDark ? 30 : 12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Column(
                              children: rest.asMap().entries.map((e) {
                                final i = e.key + 4;
                                final p = e.value;
                                final isLast = e.key == rest.length - 1;
                                return _RankingRow(
                                  position: i,
                                  project: p,
                                  isDark: isDark,
                                  isLast: isLast,
                                  onTap: () =>
                                      context.push('/project/${p.id}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

// ── Clean Podium ────────────────────────────────────────────────────────────
// No gradients — depth achieved through solid color, size hierarchy, and shadows.

class _CleanPodium extends StatelessWidget {
  const _CleanPodium({required this.top3, required this.isDark});
  final List<ProjectReadModel> top3;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Reorder: 2nd (left), 1st (center/tallest), 3rd (right)
    final ordered = [
      if (top3.length > 1) (pos: 2, p: top3[1]),
      (pos: 1, p: top3[0]),
      if (top3.length > 2) (pos: 3, p: top3[2]),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 14),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ordered.map((item) {
          // Height hierarchy: 1st is tallest, creates natural podium shape
          final barHeight = item.pos == 1
              ? 100.0
              : item.pos == 2
                  ? 76.0
                  : 60.0;

          // Medal icon per position
          final medalIcon = item.pos == 1
              ? Icons.emoji_events_rounded
              : item.pos == 2
                  ? Icons.workspace_premium_rounded
                  : Icons.military_tech_rounded;

          // Medal color — solid, no gradients
          // 1st: vibrant green (primary CTA), 2nd/3rd: olive (secondary/support)
          final medalColor = item.pos == 1
              ? AppColors.lightPrimary
              : AppColors.lightOlive;

          // Podium bar — solid fill, no gradient
          // 1st: green accent fill, others: olive with low opacity
          final barColor = item.pos == 1
              ? AppColors.lightPrimary.withAlpha(230)
              : AppColors.lightOlive.withAlpha(isDark ? 80 : 40);

          final positionTextColor = item.pos == 1
              ? Colors.white
              : (isDark ? AppColors.lightOlive : AppColors.lightOlive);

          return Expanded(
            child: GestureDetector(
              onTap: () => context.push('/project/${item.p.id}'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Medal icon
                  Icon(medalIcon, color: medalColor,
                      size: item.pos == 1 ? 28 : 22),
                  const SizedBox(height: 6),

                  // Project name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item.p.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: item.pos == 1 ? 12.5 : 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightForeground,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Score — solid color, no ShaderMask gradient
                  Text(
                    '${item.p.avgScore.toStringAsFixed(1)} pts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: item.pos == 1 ? 12 : 11,
                      fontWeight: FontWeight.w700,
                      color: medalColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Podium bar — solid, clean
                  Container(
                    height: barHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sm),
                        topRight: Radius.circular(AppRadius.sm),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.pos}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: item.pos == 1 ? 24 : 20,
                        fontWeight: FontWeight.w900,
                        color: positionTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Ranking Row — Clean card-style list item ──────────────────────────────────

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.project,
    required this.isDark,
    required this.isLast,
    required this.onTap,
  });

  final int position;
  final ProjectReadModel project;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16, vertical: AppSpacing.sp14),
            child: Row(
              children: [
                // Position number — muted grey, clean and minimal
                SizedBox(
                  width: 28,
                  child: Text(
                    '$position',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),

                // Project name — strong weight
                Expanded(
                  child: Text(
                    project.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Score — vibrant green, solid color (no ShaderMask)
                Text(
                  '${project.avgScore.toStringAsFixed(1)} pts',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp8),
                Icon(Icons.chevron_right_rounded,
                    color: textSecondary, size: 18),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: BioDivider(),
          ),
      ],
    );
  }
}

// ── Skeletons de carga ─────────────────────────────────────────────────────

class _RankingSkeletons extends StatelessWidget {
  const _RankingSkeletons();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp20),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp12),
      itemBuilder: (_, i) => Row(
        children: [
          BioSkeleton(width: 24, height: 16, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: BioSkeleton(
              height: 14,
              radius: AppRadius.sm,
              width: double.infinity,
            ),
          ),
          const SizedBox(width: AppSpacing.sp16),
          BioSkeleton(width: 40, height: 14, radius: AppRadius.sm),
        ],
      ),
    );
  }
}
