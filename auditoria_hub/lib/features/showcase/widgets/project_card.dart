// features/showcase/widgets/project_card.dart — Tarjeta de proyecto (Biofrost)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/models/project_read_model.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});

  final ProjectReadModel project;
  final VoidCallback onTap;

  static const _thumbnailBgs = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
    Color(0xFF1B1B2F),
    Color(0xFF2C2C54),
  ];

  Color _thumbBg() {
    final idx =
        project.title.codeUnits.fold(0, (a, b) => a + b) % _thumbnailBgs.length;
    return _thumbnailBgs[idx];
  }

  String _initials() {
    final words = project.title.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return project.title
        .substring(0, project.title.length.clamp(0, 2))
        .toUpperCase();
  }

  ProjectStatus _parseStatus() {
    switch (project.status.toLowerCase()) {
      case 'active':
      case 'activo':
        return ProjectStatus.active;
      case 'completed':
      case 'completado':
        return ProjectStatus.completed;
      default:
        return ProjectStatus.draft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(46),
              blurRadius: 5,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail (60%) ──────────────────────────────────────
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image or fallback
                      if (project.coverImageUrl != null)
                        CachedNetworkImage(
                          imageUrl: project.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: _thumbBg()),
                          errorWidget: (_, __, ___) => _fallbackThumb(),
                        )
                      else
                        _fallbackThumb(),

                      // Gradient fade at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                (isDark
                                        ? AppColors.darkSurface1
                                        : AppColors.lightCard)
                                    .withAlpha(200),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Visibility badge top-right
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _VisibilityBadge(isPublic: true),
                      ),
                      // Score badge bottom-left
                      if (project.avgScore > 0)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: _ScoreBadge(score: project.avgScore),
                        ),
                    ],
                  ),
                ),

                // ── Info (40%) ───────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightForeground,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        ProjectStatusDot(status: _parseStatus()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      color: _thumbBg(),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white.withAlpha(61),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(175),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.podiumGold.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 10, color: AppColors.podiumGold),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.isPublic});
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isPublic
              ? AppColors.darkSuccess.withAlpha(100)
              : AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Text(
        isPublic ? 'PÚBLICO' : 'PRIVADO',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isPublic ? AppColors.darkSuccess : AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}
