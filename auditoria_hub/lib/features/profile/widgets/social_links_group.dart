import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/social_type.dart';

class SocialLinksGroup extends StatelessWidget {
  const SocialLinksGroup({
    super.key,
    required this.socialLinks,
    required this.isDark,
    required this.onEditRequested,
  });

  final Map<String, String> socialLinks;
  final bool isDark;
  final ValueChanged<SocialType> onEditRequested;

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final dividerColor = isDark
        ? AppColors.darkBorder.withAlpha(100)
        : AppColors.lightBorder.withAlpha(150);

    const visibleTypes = [
      SocialType.github,
      SocialType.linkedin,
      SocialType.website,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 28 : 9),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: List.generate(
              visibleTypes.length * 2 - 1,
              (i) {
                if (i.isOdd) {
                  return Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: dividerColor,
                    indent: AppSpacing.sp62,
                  );
                }
                final type = visibleTypes[i ~/ 2];
                final url = socialLinks[type.name];
                final isFilled = url != null && url.trim().isNotEmpty;

                return _ShadcnSocialItem(
                  type: type,
                  url: isFilled ? url : null,
                  isDark: isDark,
                  isLast: i == visibleTypes.length * 2 - 2,
                  onTap: isFilled
                      ? () => _launchUrl(url)
                      : () => onEditRequested(type),
                  onEdit: () => onEditRequested(type),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShadcnSocialItem extends StatefulWidget {
  const _ShadcnSocialItem({
    required this.type,
    required this.isDark,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    this.url,
  });

  final SocialType type;
  final String? url;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  State<_ShadcnSocialItem> createState() => _ShadcnSocialItemState();
}

class _ShadcnSocialItemState extends State<_ShadcnSocialItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _isFilled => widget.url != null;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    final iconBg = _isFilled
        ? AppColors.lightPrimary.withAlpha(18)
        : AppColors.lightOlive.withAlpha(15);
    final iconColor = _isFilled ? AppColors.lightPrimary : AppColors.lightOlive;
    final valueLabel =
        _isFilled ? _extractDomain(widget.url!) : widget.type.emptySubtitle;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: AppColors.lightPrimary.withAlpha(12),
          highlightColor: AppColors.lightPrimary.withAlpha(8),
          onTapDown: (_) => _anim.forward(),
          onTapUp: (_) => _anim.reverse(),
          onTapCancel: () => _anim.reverse(),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sp16,
              right: AppSpacing.sp16,
              top: AppSpacing.sp14,
              bottom: widget.isLast ? AppSpacing.sp16 : AppSpacing.sp14,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(widget.type.icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.sp14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.type.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        valueLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _isFilled ? AppColors.lightPrimary : textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sp8),
                if (_isFilled) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.lightPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sp6),
                ] else ...[
                  Text(
                    'Agregar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onEdit();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final path =
          uri.path.length > 1 ? uri.path.replaceAll(RegExp(r'/$'), '') : '';
      return '${uri.host}$path';
    } catch (_) {
      return url;
    }
  }
}
