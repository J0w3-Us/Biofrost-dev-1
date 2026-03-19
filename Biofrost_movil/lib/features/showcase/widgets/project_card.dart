import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Widget _buildImagePlaceholder(Color bgColor, Color iconColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Icon(Icons.hub_outlined,
            color: iconColor.withOpacity(0.3), size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface0 : AppColors.lightMuted;
    final surfaceColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightPrimary;
    final chipBg = isDark ? AppColors.darkSurface2 : AppColors.lightMuted;

    final mergedTags = <String>{
      ...widget.project.tags.where((t) => t.trim().isNotEmpty),
      ...widget.project.techStack.where((t) => t.trim().isNotEmpty),
    };
    final allTags = mergedTags.isNotEmpty
        ? mergedTags.take(4).toList()
        : <String>[widget.project.category, '${widget.project.year}'];

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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: isDark ? 10 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cover Image & Header ──
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.project.coverImageUrl != null)
                        CachedNetworkImage(
                          imageUrl: widget.project.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: bgColor),
                          errorWidget: (context, url, error) =>
                              _buildImagePlaceholder(bgColor, textSecondary),
                        )
                      else
                        _buildImagePlaceholder(bgColor, textSecondary),

                      // Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                bgColor.withOpacity(isDark ? 0.92 : 0.75),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Categoria / State pill
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                surfaceColor.withOpacity(isDark ? 0.7 : 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accentColor.withOpacity(0.55)),
                          ),
                          child: Text(
                            widget.project.category.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.project.description.isNotEmpty
                          ? widget.project.description
                          : 'Sin descripción.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    if (allTags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allTags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
