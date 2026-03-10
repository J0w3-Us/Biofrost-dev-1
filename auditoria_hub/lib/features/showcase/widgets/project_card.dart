// features/showcase/widgets/project_card.dart — Instagram-style feed card (Biofrost v3)
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/models/project_read_model.dart';

class ProjectCard extends StatefulWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});

  final ProjectReadModel project;
  final VoidCallback onTap;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  static const _thumbnailBgs = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
    Color(0xFF1B1B2F),
    Color(0xFF2C2C54),
  ];

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color _thumbBg() {
    final idx = widget.project.title.codeUnits.fold(0, (a, b) => a + b) %
        _thumbnailBgs.length;
    return _thumbnailBgs[idx];
  }

  String _initials() {
    final words = widget.project.title.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return widget.project.title
        .substring(0, widget.project.title.length.clamp(0, 2))
        .toUpperCase();
  }

  ProjectStatus _parseStatus() {
    switch (widget.project.status.toLowerCase()) {
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
    final status = _parseStatus();

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (ctx, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (Instagram-style) ─────────────────────────────────
            _InstaHeader(
              project: widget.project,
              status: status,
              initials: _initials(),
              isDark: isDark,
            ),
            // ── Full-width Cover Image ───────────────────────────────────
            _InstaImage(
              project: widget.project,
              thumbBg: _thumbBg(),
              initials: _initials(),
            ),
            // ── Footer ───────────────────────────────────────────────────
            _InstaFooter(project: widget.project, isDark: isDark),
            // ── Divider between posts ────────────────────────────────────
            Divider(
              height: 24,
              thickness: 0.5,
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder.withAlpha(160),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instagram-style Header ────────────────────────────────────────────────────

class _InstaHeader extends StatelessWidget {
  const _InstaHeader({
    required this.project,
    required this.status,
    required this.initials,
    required this.isDark,
  });

  final ProjectReadModel project;
  final ProjectStatus status;
  final String initials;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      ProjectStatus.active => 'ACTIVO',
      ProjectStatus.completed => 'COMPLETADO',
      ProjectStatus.draft => 'BORRADOR',
    };
    final statusColor = switch (status) {
      ProjectStatus.active => AppColors.darkSuccess,
      ProjectStatus.completed => AppColors.darkAccent,
      ProjectStatus.draft => AppColors.darkTextSecondary,
    };
    final statusBg = switch (status) {
      ProjectStatus.active => AppColors.badgeActiveBg,
      ProjectStatus.completed => AppColors.badgeCompletoBg,
      ProjectStatus.draft => AppColors.badgeBorradorBg,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar — gradient ring inspired by IG story ring
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B9D),
                  Color(0xFFFF8C5A),
                  Color(0xFFA855F7),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface0 : AppColors.lightCard,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials[0],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.teamName.isNotEmpty
                      ? project.teamName
                      : 'Sin equipo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  project.year.toString(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightMutedFg,
                  ),
                ),
              ],
            ),
          ),
          // Status pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: statusColor.withAlpha(80),
                width: 0.8,
              ),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instagram-style Full-width Image ─────────────────────────────────────────

class _InstaImage extends StatelessWidget {
  const _InstaImage({
    required this.project,
    required this.thumbBg,
    required this.initials,
  });

  final ProjectReadModel project;
  final Color thumbBg;
  final String initials;

  @override
  Widget build(BuildContext context) {
    // Full square (1:1) like Instagram, can adjust to 4:5 or 16:9
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (project.coverImageUrl != null)
            CachedNetworkImage(
              imageUrl: project.coverImageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  _FallbackImage(thumbBg: thumbBg),
              errorWidget: (_, __, ___) =>
                  _FallbackImage(thumbBg: thumbBg),
            )
          else
            _FallbackImage(thumbBg: thumbBg),

          // Very subtle gradient scrim at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(80),
                  ],
                ),
              ),
            ),
          ),

          // Score badge (IG-style — glassmorphism, bottom-left)
          if (project.avgScore > 0)
            Positioned(
              bottom: 10,
              left: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(110),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AppColors.podiumGold.withAlpha(80),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.podiumGold),
                        const SizedBox(width: 3),
                        Text(
                          project.avgScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.thumbBg});
  final Color thumbBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: thumbBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 34, color: Colors.white.withAlpha(55)),
          const SizedBox(height: 8),
          Text(
            'Sin contenido visual',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withAlpha(75),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instagram-style Footer ────────────────────────────────────────────────────

class _InstaFooter extends StatelessWidget {
  const _InstaFooter({required this.project, required this.isDark});
  final ProjectReadModel project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasDescription = project.description.trim().isNotEmpty;
    final hasScore = project.avgScore > 0;
    final primaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star rating row (IG-like action row)
          Row(
            children: [
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = hasScore && i < project.avgScore.round();
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 17,
                      color: filled
                          ? AppColors.podiumGold
                          : mutedColor.withAlpha(120),
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Ver más
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver más',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.open_in_new_rounded, size: 13, color: mutedColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title — bold, IG-style
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${project.title}  ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: -0.2,
                  ),
                ),
                TextSpan(
                  text: hasDescription
                      ? project.description
                      : 'Sin descripción disponible.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: primaryColor.withAlpha(210),
                    height: 1.45,
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
