// features/dashboard/pages/dashboard_page.dart — Panel del Docente
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
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
                        height: 90,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total',
                              value: '${dash.total}',
                              icon: Icons.folder_outlined,
                              color: const Color(0xFF2563EB),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              label: 'Pendientes',
                              value: '${dash.pendientes}',
                              icon: Icons.access_time_rounded,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              label: 'Aprobados',
                              value: '${dash.aprobados}',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.success,
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
                  decoration: InputDecoration(
                    hintText: 'Buscar proyecto o alumno...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
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
                  onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    dash.projects.isEmpty
                        ? 'No tienes proyectos asignados'
                        : 'Sin resultados para "$_query"',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightMutedFg,
                    ),
                  ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $teacherName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Panel de evaluaciones',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
              fontSize: 10,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
    if (project.pendienteDeEvaluar) return const Color(0xFFF59E0B);
    if (project.aprobado) return AppColors.success;
    if (project.calificacion != null) return const Color(0xFFEF4444);
    return AppColors.darkTextSecondary;
  }

  String get _statusLabel {
    if (project.pendienteDeEvaluar) return 'Pendiente';
    if (project.aprobado)
      return '✓ ${project.calificacion!.toStringAsFixed(0)}';
    if (project.calificacion != null) {
      return '✗ ${project.calificacion!.toStringAsFixed(0)}';
    }
    if (!project.esPublico) return 'Sin publicar';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface1 : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Thumbnail o placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                border: Border.all(color: _statusColor.withAlpha(80)),
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
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
