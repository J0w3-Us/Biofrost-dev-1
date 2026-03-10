// features/dashboard/pages/dashboard_page.dart — Panel del Docente
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bio_empty_state.dart';
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
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ) // Added missing ')' here
                    : Column(
                          children: [
                            // Top row: Total spans full width
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total de Proyectos',
                                    value: '${dash.total}',
                                    icon: Icons.folder_outlined,
                                    color: const Color(0xFF3B82F6), // Blue
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Bottom row: Pendientes and Aprobados
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Pendientes',
                                    value: '${dash.pendientes}',
                                    icon: Icons.access_time_rounded,
                                    color: const Color(0xFFF59E0B), // Amber
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Aprobados',
                                    value: '${dash.aprobados}',
                                    icon: Icons.check_circle_outline_rounded,
                                    color: const Color(0xFF10B981), // Emerald
                                    isDark: isDark,
                                  ),
                                ),
                              ],
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
                hasScrollBody: false,
                child: dash.projects.isEmpty
                    ? _HeroBanner(isDark: isDark)
                    : BioEmptyState(
                        title: 'Sin resultados',
                        subtitle: 'No se encontraron proyectos para "$_query".',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D1B3E), // deep navy
              Color(0xFF1A2B5A), // mid blue
              Color(0xFF0A1628), // dark ink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B5A).withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hola, $teacherName 👋',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Viendo tus proyectos asignados',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ── Aurora Pill Button (identidad Biofrost) ────────────────

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
    final bgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Inner top highlight (simulating glassmorphism specular reflection)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(isDark ? 15 : 40),
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with localized glow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 30 : 20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(isDark ? 60 : 40), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(isDark ? 40 : 20),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 16),
                  // Value (Large number)
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ── Estado vacío, editorial y elegante ───────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withAlpha(isDark ? 80 : 40),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0xFF06B6D4), // Cyan 500
                Color(0xFF3B82F6), // Blue 500
                Color(0xFF4F46E5), // Indigo 600
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon circle — white border, translucent center
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
                          color: Colors.white.withAlpha(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Heading
                      const Text(
                        'Todo listo, profesor',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Body
                      Text(
                        'Cuando te asignen un proyecto para evaluar,\naparecerá justo aquí.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: Colors.white.withAlpha(230),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ── Specular highlight (top curve) ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(50),
                          Colors.white.withAlpha(0),
                        ],
                      ),
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
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
