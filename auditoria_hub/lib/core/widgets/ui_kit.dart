// core/widgets/ui_kit.dart — UI Kit Biofrost para Auditoría Hub
// Componentes: BioButton, BioInput, BioChip, UserAvatar, BioCard,
//              BioSkeleton, BioErrorView, BioEmptyView, BioDivider,
//              OfflineBanner, StatusBadge, ProjectStatusDot, CacheAgeBadge

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BioButton — Botón principal del design system
// ═══════════════════════════════════════════════════════════════════════════

enum BioButtonVariant { primary, secondary, ghost }

class BioButton extends StatelessWidget {
  const BioButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BioButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final BioButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null && !isLoading;

    final br = BorderRadius.circular(AppRadius.full);
    final isPrimary = variant == BioButtonVariant.primary;
    final isSecondary = variant == BioButtonVariant.secondary;

    final Color textColor = isPrimary
      ? (isDark ? AppColors.darkTextInverse : AppColors.lightCard)
        : isSecondary
            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightForeground)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg);

    final Color bgColor = isPrimary
        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
        : isSecondary
            ? Colors.transparent
            : Colors.transparent;

    final BoxBorder? border = isSecondary
        ? Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          )
        : null;

    return AnimatedOpacity(
      opacity: isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: br,
          color: bgColor,
          border: border,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPressed,
            splashColor: Colors.white.withAlpha(25),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioChip — Chip de tecnología / filtro
// ═══════════════════════════════════════════════════════════════════════════

class BioChip extends StatelessWidget {
  const BioChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12, vertical: AppSpacing.sp6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface3 : AppColors.lightSecondary)
              : (isDark ? AppColors.darkSurface2 : AppColors.lightMuted),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkBorderFocus : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground)
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UserAvatar — Avatar con fallback de iniciales
// ═══════════════════════════════════════════════════════════════════════════

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.showBorder = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool showBorder;

  static const _fallbackColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0891B2), // Cyan
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Pink
    Color(0xFF2563EB), // Blue
  ];

  String _initials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _bgColor() {
    final idx =
        name.codeUnits.fold(0, (a, b) => a + b) % _fallbackColors.length;
    return _fallbackColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    } else {
      avatar = _fallbackAvatar();
    }

    if (showBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return SizedBox(width: size, height: size, child: avatar);
  }

  Widget _fallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: AppColors.lightCard,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioCard — Contenedor tarjeta
// ═══════════════════════════════════════════════════════════════════════════

class BioCard extends StatelessWidget {
  const BioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp16),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(46),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: Colors.white.withAlpha(8),
                  child: Padding(padding: padding, child: child),
                ),
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioSkeleton — Placeholder pulsante de carga
// ═══════════════════════════════════════════════════════════════════════════

class BioSkeleton extends StatefulWidget {
  const BioSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<BioSkeleton> createState() => _BioSkeletonState();
}

class _BioSkeletonState extends State<BioSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    // Sweep from -2 to 2 so the shimmer band fully traverses the widget
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface2 : AppColors.lightSecondary;
    final highlight = isDark ? AppColors.darkSurface3 : AppColors.lightCard;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1.0, 0),
              end: Alignment(t + 1.0, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioErrorView — Vista de error con botón reintentar
// ═══════════════════════════════════════════════════════════════════════════

class BioErrorView extends StatelessWidget {
  const BioErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: AppSpacing.sp48,
              color:
                  isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
            ),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sp16),
              BioButton(
                label: 'Reintentar',
                variant: BioButtonVariant.secondary,
                onPressed: onRetry,
                width: 140,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioEmptyView — Vista vacía
// ═══════════════════════════════════════════════════════════════════════════

class BioEmptyView extends StatelessWidget {
  const BioEmptyView({
    super.key,
    this.title = 'Sin resultados',
    this.subtitle = 'Intenta con otro término de búsqueda',
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glow container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withAlpha(30),
                    Colors.transparent,
                  ],
                  radius: 0.9,
                ),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(icon, size: 26, color: mutedColor),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.sp6),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioDivider — Divisor con etiqueta opcional
// ═══════════════════════════════════════════════════════════════════════════

class BioDivider extends StatelessWidget {
  const BioDivider({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (label == null) {
      return Divider(color: lineColor, thickness: 1, height: 1);
    }

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
          child: Text(
            label!.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color:
                  isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OfflineBanner — Franja de sin conexión
// ═══════════════════════════════════════════════════════════════════════════

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: visible
          ? Container(
              width: double.infinity,
              color: AppColors.warning,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sp6,
                horizontal: AppSpacing.sp16,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      Icons.wifi_off_rounded,
                      size: 14,
                      color: AppColors.lightCard),
                  SizedBox(width: AppSpacing.sp6),
                  Text(
                    'Sin conexión — mostrando datos en caché',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightCard,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CacheAgeBadge — Indicador de antigüedad del caché
// ═══════════════════════════════════════════════════════════════════════════

class CacheAgeBadge extends StatelessWidget {
  const CacheAgeBadge({super.key, required this.updatedAt});
  final DateTime updatedAt;

  String _label() {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Actualizado hace un momento';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded,
            size: 11,
            color:
                isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg),
        const SizedBox(width: 4),
        Text(
          _label(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// StatusBadge — Badge de estado del proyecto
// ═══════════════════════════════════════════════════════════════════════════

enum ProjectStatus { active, completed, draft }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ProjectStatus.active:
        bg = AppColors.badgeActiveBg;
        fg = AppColors.darkSuccess;
        label = 'ACTIVO';
        break;
      case ProjectStatus.completed:
        bg = AppColors.badgeCompletoBg;
        fg = AppColors.darkInfo;
        label = 'COMPLETADO';
        break;
      case ProjectStatus.draft:
        bg = AppColors.badgeBorradorBg;
        fg = AppColors.darkTextSecondary;
        label = 'BORRADOR';
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ProjectStatusDot — Punto de estado con glow
// ═══════════════════════════════════════════════════════════════════════════

class ProjectStatusDot extends StatelessWidget {
  const ProjectStatusDot({super.key, required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case ProjectStatus.active:
        color = AppColors.darkSuccess;
        label = 'Activo';
        break;
      case ProjectStatus.completed:
        color = AppColors.darkInfo;
        label = 'Completado';
        break;
      case ProjectStatus.draft:
        color = AppColors.darkTextSecondary;
        label = 'Borrador';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withAlpha(100), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BioSnackBar — Helper para mostrar toasts estilo Biofrost
// ═══════════════════════════════════════════════════════════════════════════

enum BioToastType { success, error, warning, info }

class BioSnackBar {
  static void show(
    BuildContext context,
    String message,
    BioToastType type, {
    VoidCallback? onRetry,
  }) {
    Color borderColor;
    IconData icon;
    Duration duration;

    switch (type) {
      case BioToastType.success:
        borderColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        duration = const Duration(seconds: 4);
        break;
      case BioToastType.error:
        borderColor = AppColors.error;
        icon = Icons.error_outline_rounded;
        duration = const Duration(seconds: 6);
        break;
      case BioToastType.warning:
        borderColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        duration = const Duration(seconds: 5);
        break;
      case BioToastType.info:
        borderColor = AppColors.info;
        icon = Icons.info_outline_rounded;
        duration = const Duration(seconds: 3);
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: borderColor, size: 20),
            const SizedBox(width: AppSpacing.sp8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor, width: 1),
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Reintentar',
                textColor: borderColor,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
