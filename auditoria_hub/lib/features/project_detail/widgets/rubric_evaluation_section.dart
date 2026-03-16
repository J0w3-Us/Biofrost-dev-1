import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/micro_interactions.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/commands/submit_evaluation_command.dart';
import '../domain/models/project_detail_read_model.dart';
import '../providers/evaluation_engine_provider.dart';
import '../providers/project_detail_provider.dart';

class RubricEvaluationSection extends ConsumerStatefulWidget {
  const RubricEvaluationSection({
    super.key,
    required this.projectId,
    required this.isDark,
  });

  final String projectId;
  final bool isDark;

  @override
  ConsumerState<RubricEvaluationSection> createState() =>
      _RubricEvaluationSectionState();
}

class _RubricEvaluationSectionState
    extends ConsumerState<RubricEvaluationSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(projectDetailProvider(widget.projectId));
      ref
          .read(evaluationEngineProvider(widget.projectId).notifier)
          .hydrateFromEvaluation(state.project?.myEvaluation);
    });
  }

  void _submit(EvaluationEngineState engineState, EvaluationStatus status) {
    ref.read(projectDetailProvider(widget.projectId).notifier).submitEvaluation(
          SubmitEvaluationCommand(
            projectId: widget.projectId,
            criteria: engineState.criteria,
            weightedTotalScore: engineState.weightedTotalScore,
            status: status,
          ),
        );
  }

  void _onSaveDraft(EvaluationEngineState engineState) {
    HapticFeedback.lightImpact();
    if (!engineState.hasAnyScore) {
      BioSnackBar.show(
        context,
        'Selecciona al menos un criterio para guardar borrador.',
        BioToastType.warning,
      );
      return;
    }

    ref
        .read(evaluationEngineProvider(widget.projectId).notifier)
        .setDraftStatus();
    _submit(engineState, EvaluationStatus.draft);
  }

  void _onSubmit(EvaluationEngineState engineState) {
    HapticFeedback.lightImpact();
    if (!engineState.isComplete) {
      BioSnackBar.show(
        context,
        'Debes completar todos los criterios para enviar la evaluacion final.',
        BioToastType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _VoteConfirmSheet(
        isDark: widget.isDark,
        weightedScore: engineState.weightedTotalScore,
        onConfirm: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          ref
              .read(evaluationEngineProvider(widget.projectId).notifier)
              .setCompletedStatus();
          _submit(engineState, EvaluationStatus.completed);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectDetailProvider(widget.projectId), (previous, next) {
      final prevEval = previous?.project?.myEvaluation;
      final nextEval = next.project?.myEvaluation;

      if (prevEval == null && nextEval != null) {
        ref
            .read(evaluationEngineProvider(widget.projectId).notifier)
            .hydrateFromEvaluation(nextEval);
      }
    });

    final primaryColor =
        widget.isDark ? AppColors.darkAccent : AppColors.lightPrimary;
    final submitState = ref.watch(projectDetailProvider(widget.projectId));
    final engineState = ref.watch(evaluationEngineProvider(widget.projectId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rubrica de evaluacion',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Asigna un puntaje de 1 a 5 por criterio.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: widget.isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightMutedFg,
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          ...engineState.criteria.map(
            (criterion) => _RubricCriterionCard(
              criterion: criterion,
              isDark: widget.isDark,
              onSelected: (score) {
                HapticFeedback.selectionClick();
                ref
                    .read(evaluationEngineProvider(widget.projectId).notifier)
                    .updateCriterionScore(criterion.id, score);
              },
              onCommentChanged: (value) {
                ref
                    .read(evaluationEngineProvider(widget.projectId).notifier)
                    .updateCriterionComment(criterion.id, value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sp24),
          _EvaluationSummaryBar(
            weightedTotalScore: engineState.weightedTotalScore,
            progress: engineState.progress,
            isDark: widget.isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: AppSpacing.sp16),
          Row(
            children: [
              Expanded(
                child: PressScale(
                  enabled: !submitState.isSubmitting,
                  child: BioButton(
                    onPressed: submitState.isSubmitting
                        ? null
                        : () => _onSaveDraft(engineState),
                    label: 'Guardar borrador',
                    variant: BioButtonVariant.secondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: PressScale(
                  enabled: !submitState.isSubmitting,
                  child: BioButton(
                    onPressed: submitState.isSubmitting
                        ? null
                        : () => _onSubmit(engineState),
                    label: 'Enviar evaluacion',
                    isLoading: submitState.isSubmitting,
                    variant: BioButtonVariant.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RubricCriterionCard extends StatelessWidget {
  const _RubricCriterionCard({
    required this.criterion,
    required this.isDark,
    required this.onSelected,
    required this.onCommentChanged,
  });

  final CriterionReadModel criterion;
  final bool isDark;
  final ValueChanged<int> onSelected;
  final ValueChanged<String> onCommentChanged;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final selectedColor =
        isDark ? AppColors.darkAccent : AppColors.lightPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp12),
      padding: const EdgeInsets.all(AppSpacing.sp12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '${(criterion.weight * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp10),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = criterion.score == value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelected(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withAlpha(32)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? selectedColor : border,
                          width: isSelected ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? selectedColor : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sp10),
          TextFormField(
            key: ValueKey('comment_${criterion.id}_${criterion.comment ?? ''}'),
            initialValue: criterion.comment ?? '',
            onChanged: onCommentChanged,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Comentario de ${criterion.name.toLowerCase()} (opcional)',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: textSecondary,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: selectedColor, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSummaryBar extends StatelessWidget {
  const _EvaluationSummaryBar({
    required this.weightedTotalScore,
    required this.progress,
    required this.isDark,
    required this.primaryColor,
  });

  final double weightedTotalScore;
  final double progress;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${weightedTotalScore.toStringAsFixed(1)}/100',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.darkSurface2 : AppColors.lightCard,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Avance de puntaje ${progress.toStringAsFixed(0)}%. Para enviar: completa todos los criterios.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteConfirmSheet extends StatelessWidget {
  const _VoteConfirmSheet({
    required this.isDark,
    required this.weightedScore,
    required this.onConfirm,
  });

  final bool isDark;
  final double weightedScore;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.darkAccent : AppColors.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.star_rounded,
            color: primaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Confirmar tu voto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vas a enviar una evaluacion final con ${weightedScore.toStringAsFixed(1)} puntos.',
            style: TextStyle(
              fontFamily: 'Inter',
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: PressScale(
                  child: BioButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    label: 'Cancelar',
                    variant: BioButtonVariant.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PressScale(
                  child: BioButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onConfirm();
                    },
                    label: 'Enviar',
                    variant: BioButtonVariant.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
