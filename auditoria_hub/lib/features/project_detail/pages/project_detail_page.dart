// features/project_detail/pages/project_detail_page.dart — RF-03+04 (Biofrost)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/commands/submit_evaluation_command.dart';
import '../domain/models/project_detail_read_model.dart';
import '../providers/project_detail_provider.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDetailProvider(projectId));
    final auth = ref.watch(authStateProvider);
    final isTeacher = auth is AuthAuthenticated && auth.isTeacher;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Toast listeners
    ref.listen(projectDetailProvider(projectId), (prev, next) {
      if (next.evalSuccess && !(prev?.evalSuccess ?? false)) {
        BioSnackBar.show(context, '✓ Evaluación enviada correctamente',
            BioToastType.success);
      }
      if (next.evalError != null && prev?.evalError != next.evalError) {
        BioSnackBar.show(context, next.evalError!, BioToastType.error,
            onRetry: () {});
      }
    });

    if (state.isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
        appBar: AppBar(
          leading: _BackButton(isDark: isDark),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(leading: _BackButton(isDark: isDark)),
        body: BioErrorView(
          message: state.error!,
          onRetry: () =>
              ref.read(projectDetailProvider(projectId).notifier).reload(),
        ),
      );
    }

    final project = state.project!;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            leading: _BackButton(isDark: isDark),
            title: Text(
              project.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.ios_share_rounded,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightForeground,
                  size: 20,
                ),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: 'Mira este proyecto: ${project.title}'),
                ),
              ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.sp16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Project Header
                _ProjectHeader(project: project, isDark: isDark),
                const SizedBox(height: AppSpacing.sp20),

                // Description
                _Section(
                  title: 'Descripción',
                  isDark: isDark,
                  child: BioCard(
                    child: Text(
                      project.description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightMutedFg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp20),

                // Tech Stack
                if (project.techStack.isNotEmpty) ...[
                  _Section(
                    title: 'Stack tecnológico',
                    isDark: isDark,
                    child: Wrap(
                      spacing: AppSpacing.sp8,
                      runSpacing: AppSpacing.sp8,
                      children: project.techStack
                          .map((t) => BioChip(label: t))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                ],

                // Info row
                _Section(
                  title: 'Información',
                  isDark: isDark,
                  child: BioCard(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.group_outlined,
                          label: 'Equipo',
                          value: project.teamName,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sp8),
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Categoría',
                          value: project.category,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sp8),
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Año',
                          value: '${project.year}',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sp8),
                        _DetailRow(
                          icon: Icons.star_rounded,
                          label: 'Puntuación',
                          value:
                              '${project.avgScore.toStringAsFixed(1)} ⭐ (${project.totalVotes} votos)',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp20),

                // Team members
                if (project.teamMembers.isNotEmpty) ...[
                  _Section(
                    title: 'Equipo (${project.teamMembers.length})',
                    isDark: isDark,
                    child: Column(
                      children: [
                        ...project.teamMembers.asMap().entries.map((e) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  UserAvatar(
                                    name: e.value,
                                    size: 40,
                                    showBorder: true,
                                  ),
                                  const SizedBox(width: AppSpacing.sp12),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (e.key < project.teamMembers.length - 1) ...[
                                const SizedBox(height: AppSpacing.sp12),
                                const BioDivider(),
                                const SizedBox(height: AppSpacing.sp12),
                              ],
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                ],

                // Evaluation (docentes)
                if (isTeacher) ...[
                  _Section(
                    title: 'Evaluación',
                    isDark: isDark,
                    child: _EvaluationSection(
                        projectId: project.id, isDark: isDark),
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                ],

                // PDF download card (siempre visible)
                _Section(
                  title: 'Recursos',
                  isDark: isDark,
                  child: _PdfDownloadCard(
                    projectTitle: project.title,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back Button ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightForeground,
      ),
      onPressed: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }
}

// ── Project Header ─────────────────────────────────────────────────────────

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project, required this.isDark});
  final ProjectDetailReadModel project;
  final bool isDark;

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: project.coverImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: project.coverImageUrl!,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 88,
                  height: 88,
                  color: isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
                  child: const Icon(Icons.assignment_outlined, size: 36),
                ),
        ),
        const SizedBox(width: AppSpacing.sp16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Wrap(
                spacing: AppSpacing.sp6,
                runSpacing: AppSpacing.sp6,
                children: [
                  StatusBadge(status: _parseStatus()),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.lightMuted,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Text(
                      project.category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightMutedFg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.isDark,
  });
  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        child,
      ],
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Already Evaluated Banner ──────────────────────────────────────────────

class _AlreadyEvaluatedBanner extends StatelessWidget {
  const _AlreadyEvaluatedBanner({required this.eval, required this.isDark});
  final EvaluationReadModel eval;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.badgeCompletoBg, AppColors.darkSurface2]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark
              ? AppColors.darkSuccess.withAlpha(80)
              : AppColors.success.withAlpha(120),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.darkSuccess,
              ),
              const SizedBox(width: 6),
              Text(
                'Ya evaluaste este proyecto',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp8),
          // Stars row
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < eval.stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: Colors.amber,
              );
            }),
          ),
          if (eval.feedback != null && eval.feedback!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sp6),
            Text(
              '"${eval.feedback}"',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── PDF Download Card ──────────────────────────────────────────────────────

class _PdfDownloadCard extends StatefulWidget {
  const _PdfDownloadCard({required this.projectTitle, required this.isDark});
  final String projectTitle;
  final bool isDark;

  @override
  State<_PdfDownloadCard> createState() => _PdfDownloadCardState();
}

class _PdfDownloadCardState extends State<_PdfDownloadCard> {
  bool _generating = false;

  Future<void> _generate() async {
    HapticFeedback.lightImpact();
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _generating = false);
    BioSnackBar.show(
      context,
      'El reporte PDF estará disponible próximamente',
      BioToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return BioCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withAlpha(50),
                  primaryColor.withAlpha(20)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: primaryColor.withAlpha(80)),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 22,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte del proyecto',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                ),
                Text(
                  'Resumen completo en PDF',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightMutedFg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _generating
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: primaryColor,
                    ),
                  )
                : IconButton(
                    key: const ValueKey('button'),
                    onPressed: _generate,
                    icon: Icon(
                      Icons.download_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    tooltip: 'Descargar PDF',
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Evaluation Section ─────────────────────────────────────────────────────

class _EvaluationSection extends ConsumerStatefulWidget {
  const _EvaluationSection({required this.projectId, required this.isDark});
  final String projectId;
  final bool isDark;

  @override
  ConsumerState<_EvaluationSection> createState() => _EvaluationSectionState();
}

class _EvaluationSectionState extends ConsumerState<_EvaluationSection> {
  int _stars = 0;
  final _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _showConfirmDialog(ProjectDetailReadModel project) {
    if (_stars == 0) {
      BioSnackBar.show(
          context, 'Selecciona al menos 1 estrella', BioToastType.warning);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _stars,
                (_) => const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 20),
              ),
            ),
            if (_feedbackCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${_feedbackCtrl.text}"',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submit();
            },
            child: const Text(
              'Enviar',
              style: TextStyle(
                color: AppColors.darkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    HapticFeedback.selectionClick();
    await ref
        .read(projectDetailProvider(widget.projectId).notifier)
        .submitEvaluation(
          SubmitEvaluationCommand(
            projectId: widget.projectId,
            stars: _stars,
            feedback: _feedbackCtrl.text.isEmpty ? null : _feedbackCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailProvider(widget.projectId));
    final prev = state.project?.myEvaluation;

    return BioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner si ya evaluó ────────────────────────────────────
          if (prev != null) ...[
            _AlreadyEvaluatedBanner(eval: prev, isDark: widget.isDark),
            const SizedBox(height: AppSpacing.sp16),
            Divider(
              color:
                  widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
              height: 1,
            ),
            const SizedBox(height: AppSpacing.sp16),
          ],
          Text(
            prev != null ? 'Modificar tu evaluación' : 'Califica este proyecto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.sp12),
          RatingBar.builder(
            initialRating: (prev?.stars ?? _stars).toDouble(),
            minRating: 1,
            itemCount: 5,
            itemSize: 32,
            itemBuilder: (_, __) =>
                const Icon(Icons.star_rounded, color: Colors.amber),
            onRatingUpdate: (r) => setState(() => _stars = r.toInt()),
          ),
          const SizedBox(height: AppSpacing.sp12),
          TextField(
            controller: _feedbackCtrl,
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
            decoration: const InputDecoration(
              hintText: 'Retroalimentación (opcional)...',
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          BioButton(
            label: state.isSubmitting ? 'Enviando...' : 'Enviar evaluación',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting
                ? null
                : () => _showConfirmDialog(state.project!),
          ),
        ],
      ),
    );
  }
}
