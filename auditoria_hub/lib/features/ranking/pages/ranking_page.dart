// features/ranking/pages/ranking_page.dart — Pantalla de ranking (Biofrost)
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
        title: const Text('Ranking'),
        automaticallyImplyLeading: false,
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
                    // ── Podio ──────────────────────────────────────────────
                    if (top3.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.sp16,
                            AppSpacing.sp20, AppSpacing.sp16, AppSpacing.sp16),
                        child: _Podium(top3: top3, isDark: isDark),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16,
                            vertical: AppSpacing.sp8),
                        child: BioDivider(label: 'Clasificación'),
                      ),
                    ],

                    // ── Lista posiciones 4+ ────────────────────────────────
                    ...rest.asMap().entries.map((e) {
                      final i = e.key + 4;
                      final p = e.value;
                      return _RankingRow(
                        position: i,
                        project: p,
                        isDark: isDark,
                        onTap: () => context.push('/project/${p.id}'),
                      );
                    }),
                  ],
                ),
    );
  }
}

// ── Podio ──────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.top3, required this.isDark});
  final List<ProjectReadModel> top3;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Reorder: 2nd, 1st, 3rd
    final ordered = [
      if (top3.length > 1) (pos: 2, p: top3[1]),
      (pos: 1, p: top3[0]),
      if (top3.length > 2) (pos: 3, p: top3[2]),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: ordered.map((item) {
        final height = item.pos == 1
            ? 110.0
            : item.pos == 2
                ? 90.0
                : 75.0;
        final medal = item.pos == 1
            ? '🥇'
            : item.pos == 2
                ? '🥈'
                : '🥉';
        final medalSize = item.pos == 1 ? 28.0 : 22.0;
        final podiumColor = item.pos == 1
            ? AppColors.podiumGold
            : item.pos == 2
                ? AppColors.podiumSilver
                : AppColors.podiumBronze;

        return Expanded(
          child: GestureDetector(
            onTap: () => context.push('/project/${item.p.id}'),
            child: Column(
              children: [
                Text(medal, style: TextStyle(fontSize: medalSize)),
                const SizedBox(height: 6),
                Text(
                  item.p.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: item.pos == 1 ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.p.avgScore.toStringAsFixed(1)} pts',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: podiumColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        podiumColor.withAlpha(70),
                        podiumColor.withAlpha(18),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.sm),
                      topRight: Radius.circular(AppRadius.sm),
                    ),
                    border:
                        Border.all(color: podiumColor.withAlpha(130), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${item.pos}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: podiumColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Ranking Row ────────────────────────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  final int position;
  final ProjectReadModel project;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$position',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightMutedFg,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp12),
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
                Text(
                  '${project.avgScore.toStringAsFixed(1)} pts',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          // Número de posición
          BioSkeleton(width: 24, height: 16, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.sp12),
          // Título del proyecto
          Expanded(
            child: BioSkeleton(
              height: 14,
              radius: AppRadius.sm,
              width: double.infinity,
            ),
          ),
          const SizedBox(width: AppSpacing.sp16),
          // Puntuación
          BioSkeleton(width: 40, height: 14, radius: AppRadius.sm),
        ],
      ),
    );
  }
}
