import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/nav_bar_visibility_provider.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../showcase/domain/models/project_read_model.dart';
import '../../showcase/providers/showcase_provider.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  late final ScrollController _scrollController;
  late final HideOnScrollController _hideOnScrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hideOnScrollController = HideOnScrollController();
    _hideOnScrollController.attach(_scrollController, ref);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkSurface0 : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final state = ref.watch(showcaseProvider);

    final sorted = [...state.projects]
      ..sort((a, b) => b.avgScore.compareTo(a.avgScore));

    final top3 = List<ProjectReadModel?>.generate(
      3,
      (index) => index < sorted.length ? sorted[index] : null,
    );
    final rest = sorted.skip(3).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ranking',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Desempeño académico y proyectos destacados',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.emoji_events,
              color: AppColors.lightOlive,
              size: 24,
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? _RankingSkeletons(isDark: isDark)
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _PodiumSection(
                  isDark: isDark,
                  first: top3[0],
                  second: top3[1],
                  third: top3[2],
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  label: 'Clasificacion general',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                if (rest.isEmpty)
                  _NoMoreProjectsCard(isDark: isDark)
                else
                  _RankingListCard(projects: rest, isDark: isDark),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ],
    );
  }
}

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({
    required this.isDark,
    required this.first,
    required this.second,
    required this.third,
  });

  final bool isDark;
  final ProjectReadModel? first;
  final ProjectReadModel? second;
  final ProjectReadModel? third;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              isDark: isDark,
              position: 2,
              project: second,
              icon: Icons.workspace_premium,
              barHeight: 88,
              accent: AppColors.lightOlive,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSlot(
              isDark: isDark,
              position: 1,
              project: first,
              icon: Icons.emoji_events,
              barHeight: 120,
              accent: AppColors.lightPrimary,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSlot(
              isDark: isDark,
              position: 3,
              project: third,
              icon: Icons.military_tech,
              barHeight: 72,
              accent: AppColors.lightOlive,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.isDark,
    required this.position,
    required this.project,
    required this.icon,
    required this.barHeight,
    required this.accent,
    this.isPrimary = false,
  });

  final bool isDark;
  final int position;
  final ProjectReadModel? project;
  final IconData icon;
  final double barHeight;
  final Color accent;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final hasData = project != null;
    final title = hasData ? project!.title : 'Posicion disponible';
    final subtitle = hasData
        ? '${project!.avgScore.toStringAsFixed(1)} pts'
        : 'Aun sin proyecto asignado';

    return GestureDetector(
      onTap: hasData ? () => context.push('/project/${project!.id}') : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(icon, size: isPrimary ? 28 : 24, color: accent),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isPrimary ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: hasData
                  ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightForeground)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMutedFg),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasData
                  ? accent
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMutedFg),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: hasData
                    ? accent
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isPrimary ? 30 : 24,
                  fontWeight: FontWeight.w900,
                  color: hasData
                      ? accent
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightMutedFg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingListCard extends StatelessWidget {
  const _RankingListCard({required this.projects, required this.isDark});

  final List<ProjectReadModel> projects;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: projects.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == projects.length - 1;

          return _RankingRow(
            position: index + 4,
            project: item,
            isLast: isLast,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.project,
    required this.isLast,
    required this.isDark,
  });

  final int position;
  final ProjectReadModel project;
  final bool isLast;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/project/${project.id}'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$position',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightMutedFg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  project.avgScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightOlive,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightMutedFg,
                  size: 18,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              indent: 14,
              endIndent: 14,
            ),
        ],
      ),
    );
  }
}

class _NoMoreProjectsCard extends StatelessWidget {
  const _NoMoreProjectsCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.lightOlive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aun no hay mas proyectos en clasificacion. El podio superior permanece activo.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingSkeletons extends StatelessWidget {
  const _RankingSkeletons({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: BioSkeleton(height: 170, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: BioSkeleton(height: 205, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: BioSkeleton(height: 155, radius: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    BioSkeleton(width: 32, height: 32, radius: 10),
                    SizedBox(width: 10),
                    Expanded(child: BioSkeleton(height: 14, radius: 8)),
                    SizedBox(width: 14),
                    BioSkeleton(width: 34, height: 14, radius: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
