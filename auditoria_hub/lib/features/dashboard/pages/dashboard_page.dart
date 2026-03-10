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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — aurora gradient ring (identidad Biofrost)
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: isDark
                      ? const Color(0xFFFF8C5A)
                      : const Color(0xFFA855F7),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $teacherName 👋',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Panel de evaluaciones',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
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
    required this.color, // kept for API compat but not used directly
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Deep jewel-tone dark gradient — premium, not candy
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // Soft indigo glow — subtle, not loud
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(isDark ? 55 : 30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF7C3AED).withAlpha(isDark ? 45 : 25),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // ── Deep jewel gradient fill ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  // Dark indigo top → deep violet bottom — luminous from darkness
                  colors: [
                    Color(0xFF1E1B4B), // deep indigo
                    Color(0xFF2D1B69), // rich violet
                    Color(0xFF1A0A3A), // near-black violet
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with a subtle aurora tint glow behind it
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withAlpha(28),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withAlpha(70),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 12),
                  // Number — bright white, big
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label — muted white
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(140),
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Thin specular line — just 16px, feathered, no division ──
            Positioned(
              top: 0,
              left: 6,
              right: 6,
              height: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(38),
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Left luminous edge accent ──────────────────────────────
            Positioned(
              top: 12,
              left: 0,
              bottom: 12,
              width: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(0),
                      Colors.white.withAlpha(30),
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // Subtle indigo glow — deep, not loud
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(isDark ? 70 : 40),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF7C3AED).withAlpha(isDark ? 55 : 30),
              blurRadius: 40,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              // ── Deep dark gradient — like a night sky ──────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 44),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F0C2E), // deep midnight
                      Color(0xFF1A1040), // dark indigo
                      Color(0xFF2D1B69), // rich violet — aurora accent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon circle — aurora border ring, dark inside
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFFA855F7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withAlpha(100),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF13102E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pending_actions_rounded,
                            color: Color(0xFF818CF8),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Heading — clean, editorial
                    const Text(
                      'Sin proyectos aún',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Body — calm, secondary
                    Text(
                      'Cuando te asignen proyectos para evaluar,\naparecerán aquí.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: Colors.white.withAlpha(150),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // ── Thin specular line only (no division effect) ──────
              Positioned(
                top: 0,
                left: 8,
                right: 8,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(30),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Subtle aurora radial glow — bottom right ──────────
              Positioned(
                bottom: -30,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C3AED).withAlpha(60),
                        const Color(0xFF7C3AED).withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
