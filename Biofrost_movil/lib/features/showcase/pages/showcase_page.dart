// features/showcase/pages/showcase_page.dart — RF-02: Galería Feed (Biofrost v2)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bio_empty_state.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../domain/models/project_read_model.dart';
import '../providers/showcase_provider.dart';
import '../widgets/project_card.dart';

class ShowcasePage extends ConsumerStatefulWidget {
  const ShowcasePage({super.key});

  @override
  ConsumerState<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends ConsumerState<ShowcasePage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedTech = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(showcaseProvider.notifier).loadMore();
    }
  }

  List<String> _extractTechs(List projects) {
    final techs = <String>{};
    for (final p in projects) {
      techs.addAll(p.techStack as List<String>);
    }
    return techs.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showcaseProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final filters = ref.watch(showcaseFiltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final techs = _extractTechs(state.projects);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          // ── SliverAppBar (floating — hides on scroll down) ──────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
            surfaceTintColor: Colors.transparent,
            title: _isSearchExpanded
                ? SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightForeground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar proyectos...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextDisabled
                              : AppColors.lightMutedFg,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 17,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightMutedFg,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightMutedFg,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            if (_searchCtrl.text.isEmpty) {
                              setState(() => _isSearchExpanded = false);
                            } else {
                              _searchCtrl.clear();
                              ref
                                  .read(showcaseProvider.notifier)
                                  .applyFilter(filters.copyWith(search: ''));
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      onChanged: (q) {
                        setState(() {});
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (_searchCtrl.text == q) {
                            ref
                                .read(showcaseProvider.notifier)
                                .applyFilter(filters.copyWith(search: q));
                          }
                        });
                      },
                    ),
                  )
                : Text(
                    'Explorar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                  ),
            actions: [
              if (!_isSearchExpanded) ...[
                // ── Bell icon with badge ─────────────────────────────────
                Consumer(
                  builder: (_, bellRef, __) {
                    final notifs = bellRef.watch(notificationsProvider);
                    final unread = notifs.where((n) => !n.isRead).length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightForeground,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showNotificationsSheet(context, bellRef);
                          },
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lightCard,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isSearchExpanded = true;
                    });
                  },
                ),
              ],
              const SizedBox(width: 8),
            ],
            bottom: techs.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: techs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => BioChip(
                            label: techs[i],
                            isSelected: _selectedTech == techs[i],
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedTech =
                                    _selectedTech == techs[i] ? '' : techs[i];
                              });
                              ref.read(showcaseProvider.notifier).applyFilter(
                                  filters.copyWith(
                                      category: _selectedTech.isEmpty
                                          ? null
                                          : _selectedTech));
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
        body: _buildBody(state, filteredProjects, filters, isDark),
      ),
    );
  }

  // ── Notifications BottomSheet ──────────────────────────────────────────────
  void _showNotificationsSheet(BuildContext ctx, WidgetRef sheetRef) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsBottomSheet(ref: sheetRef),
    );
  }

  Widget _buildBody(
      ShowcaseState state,
      List<ProjectReadModel> filteredProjects,
      ShowcaseFilters filters,
      bool isDark) {
    if (state.isLoading) {
      return _buildSkeletons(isDark);
    }

    if (state.error != null && state.projects.isEmpty) {
      return BioErrorView(
        message: 'No se pudo cargar los proyectos.\n${state.error}',
        onRetry: () => ref.read(showcaseProvider.notifier).load(),
      );
    }

    if (filteredProjects.isEmpty) {
      final isFiltered = filters.search.isNotEmpty || filters.category != null;
      return BioEmptyState(
        title: isFiltered ? 'Sin resultados' : 'Aún no hay proyectos',
        subtitle: isFiltered
            ? 'Intenta con otro término de búsqueda'
            : 'Los proyectos aparecerán aquí pronto.',
        icon: isFiltered ? Icons.search_off_rounded : Icons.folder_open_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(showcaseProvider.notifier).load(refresh: true),
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      backgroundColor:
          isDark ? AppColors.darkSurface2 : AppColors.lightSecondary,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
            top: 0, bottom: AppSpacing.sp16),
        itemCount: filteredProjects.length + (state.hasMore ? 2 : 0),
        itemBuilder: (ctx, i) {
          final projectIndex = i;

          // Loading skeletons at the end
          if (projectIndex >= filteredProjects.length) {
            return _SkeletonFeedCard(isDark: isDark);
          }
          final project = filteredProjects[projectIndex];
          // Animate each card on entry
          return _AnimatedFeedItem(
            index: i,
            child: ProjectCard(
              project: project,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/project/${project.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletons(bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: AppSpacing.sp16),
      itemCount: 5,
      itemBuilder: (_, i) => _SkeletonFeedCard(isDark: isDark),
    );
  }
}

// ── Animated wrapper for each feed item (slide + fade in) ───────────────────

class _AnimatedFeedItem extends StatefulWidget {
  const _AnimatedFeedItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedFeedItem> createState() => _AnimatedFeedItemState();
}

class _AnimatedFeedItemState extends State<_AnimatedFeedItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 60).clamp(0, 300);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Skeleton feed card (loading state) ───────────────────────────────────────

class _SkeletonFeedCard extends StatelessWidget {
  const _SkeletonFeedCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface3
                          : AppColors.lightMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BioSkeleton(height: 12, radius: AppRadius.xs),
                        SizedBox(height: 5),
                        BioSkeleton(
                            width: 60, height: 10, radius: AppRadius.xs),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const BioSkeleton(width: 70, height: 22, radius: AppRadius.full),
                ],
              ),
            ),
            // Cover skeleton — 16:9
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: BioSkeleton(height: double.infinity, radius: 0),
            ),
            // Footer skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BioSkeleton(height: 14, radius: AppRadius.xs),
                  const SizedBox(height: 6),
                  const BioSkeleton(
                      width: double.infinity * 0.75,
                      height: 11,
                      radius: AppRadius.xs),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 3),
                            child: BioSkeleton(
                                width: 14, height: 14, radius: AppRadius.full),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const BioSkeleton(width: 55, height: 11, radius: AppRadius.xs),
                    ],
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
// ── Notifications BottomSheet ──────────────────────────────────────────────

class _NotificationsBottomSheet extends StatelessWidget {
  const _NotificationsBottomSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final fmt = DateFormat('d MMM, HH:mm', 'es');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.sp12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.sp16),

            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20),
              child: Row(
                children: [
                  Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightForeground,
                    ),
                  ),
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.clearAll();
                      },
                      child: Text(
                        'Limpiar todo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightMutedFg,
                          ),
                          const SizedBox(height: AppSpacing.sp12),
                          Text(
                            'Sin notificaciones',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightMutedFg,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sp8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp20,
                              vertical: AppSpacing.sp4),
                          leading: CircleAvatar(
                            backgroundColor: n.isRead
                                ? (isDark
                                    ? AppColors.darkSurface2
                                    : AppColors.lightMuted)
                                : (isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary)
                                    .withValues(alpha: 0.15),
                            child: Icon(
                              Icons.notifications_rounded,
                              size: 20,
                              color: n.isRead
                                  ? (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightMutedFg)
                                  : (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary),
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight:
                                  n.isRead ? FontWeight.w400 : FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightForeground,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.body.isNotEmpty)
                                Text(
                                  n.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightMutedFg,
                                  ),
                                ),
                              Text(
                                fmt.format(n.receivedAt),
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
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.markRead(n.id);
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
