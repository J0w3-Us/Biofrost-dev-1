// features/dashboard/pages/dashboard_page.dart — Panel del Docente
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bio_empty_state.dart';
import '../../../core/widgets/micro_interactions.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/teacher_project_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final dash = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final teacherName = auth is AuthAuthenticated
        ? auth.displayName.split(' ').first
        : 'Docente';

    final filtered = dash.projects.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return (p.titulo.toLowerCase().contains(q)) ||
          (p.liderNombre?.toLowerCase().contains(q) ?? false) ||
          (p.materia?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DashboardHeader(
                  teacherName: teacherName,
                  isDark: isDark,
                ),
              ),

              // ── Stat Cards ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: dash.isLoading
                      ? const SizedBox(
                          height: 72,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                label: 'Total',
                                value: '${dash.total}',
                                icon: Icons.folder_outlined,
                                color: AppColors.lightOlive,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatChip(
                                label: 'Pendientes',
                                value: '${dash.pendientes}',
                                icon: Icons.access_time_rounded,
                                color: AppColors.lightOlive,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatChip(
                                label: 'Aprobados',
                                value: '${dash.aprobados}',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.lightPrimary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // ── Buscador ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar proyecto o alumno...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightMutedFg,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightMutedFg,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // ── Lista de proyectos ─────────────────────────────────────
              if (dash.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dash.error != null)
                SliverFillRemaining(
                  child: _ErrorView(
                    message: dash.error!,
                    onRetry: () =>
                        ref.read(dashboardProvider.notifier).refresh(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: dash.projects.isEmpty
                      ? _HeroBanner(
                          isDark: isDark,
                          role:
                              auth is AuthAuthenticated ? auth.role : 'Docente',
                        )
                      : BioEmptyState(
                          title: 'Sin resultados',
                          subtitle:
                              'No se encontraron proyectos para "$_query".',
                          icon: Icons.search_off_rounded,
                          isDark: isDark,
                        ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProjectRow(
                        project: filtered[i],
                        isDark: isDark,
                        onTap: () => context.push('/project/${filtered[i].id}'),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.teacherName, required this.isDark});

  final String teacherName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hola, $teacherName',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus proyectos asignados',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 26 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ── Estado vacío, por rol ────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isDark, required this.role});
  final bool isDark;
  final String role;

  @override
  Widget build(BuildContext context) {
    late String title;
    late String subtitle;
    late IconData icon;

    if (role == 'Alumno') {
      title = 'Sin proyectos aún';
      subtitle = 'Crea un proyecto nuevo para empezar.';
      icon = Icons.add_circle_outline_rounded;
    } else if (role == 'Invitado') {
      title = 'Modo invitado';
      subtitle =
          'Estás explorando la plataforma.\nCrea una cuenta para registrar proyectos.';
      icon = Icons.person_outline_rounded;
    } else {
      title = 'Todo listo';
      subtitle = 'Cuando te asignen un proyecto para evaluar, aparecerá aquí.';
      icon = Icons.inbox_rounded;
    }

    return BioEmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isDark: isDark,
    );
  }
}

// ── Project Row ────────────────────────────────────────────────────────────

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  final TeacherProjectModel project;
  final bool isDark;
  final VoidCallback onTap;

  Color get _statusColor {
    if (project.pendienteDeEvaluar) return AppColors.lightOlive;
    if (project.aprobado) return AppColors.success;
    if (project.calificacion != null) return AppColors.error.withAlpha(180);
    return AppColors.darkTextSecondary;
  }

  String get _statusLabel {
    if (project.pendienteDeEvaluar) return 'Pendiente';
    if (project.aprobado) return project.calificacion!.toStringAsFixed(0);
    if (project.calificacion != null) {
      return project.calificacion!.toStringAsFixed(0);
    }
    if (!project.esPublico) return 'Sin publicar';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return PressScale(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 26 : 10),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail o placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: project.thumbnailUrl != null
                    ? Image.network(
                        project.thumbnailUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _Placeholder(isDark: isDark),
                      )
                    : _Placeholder(isDark: isDark),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.titulo,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.liderNombre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.liderNombre!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (project.materia != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.materia!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      child: Icon(
        Icons.folder_outlined,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
        size: 22,
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
