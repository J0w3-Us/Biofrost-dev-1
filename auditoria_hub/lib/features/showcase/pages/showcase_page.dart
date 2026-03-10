// features/showcase/pages/showcase_page.dart — RF-02: Galería Feed (Biofrost v2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bio_empty_state.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../domain/models/project_read_model.dart';
import '../providers/showcase_provider.dart';
import '../widgets/project_card.dart';

class ShowcasePage extends ConsumerStatefulWidget {
  const ShowcasePage({super.key});

  @override
  ConsumerState<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends ConsumerState<ShowcasePage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedTech = '';
  bool _isSearchExpanded = false;

  // For a subtle fade-in animation on the greeting
  late final AnimationController _greetCtrl;
  late final Animation<double> _greetFade;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _greetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _greetFade =
        CurvedAnimation(parent: _greetCtrl, curve: Curves.easeOut);
    _greetCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _greetCtrl.dispose();
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
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = auth is AuthAuthenticated ? auth.displayName : null;
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
                        fontSize: 14,
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
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide.none,
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
              if (!_isSearchExpanded)
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                  },
                ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: techs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => BioChip(
                            label: techs[i],
                            isSelected: _selectedTech == techs[i],
                            onTap: () {
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

  Widget _buildBody(
      ShowcaseState state, List<ProjectReadModel> filteredProjects, ShowcaseFilters filters, bool isDark) {
    if (state.isLoading) {
      return _buildSkeletons(isDark);
    }

    if (state.error != null && state.projects.isEmpty) {
      return BioErrorView(
        message: 'No se pudo cargar los proyectos.\n${state.error}',
        onRetry: () => ref.read(showcaseProvider.notifier).load(),
      );
    }

    if (!state.isLoading && filteredProjects.isEmpty) {
      final isFiltered =
          filters.search.isNotEmpty || filters.category != null;
      return BioEmptyState(
        title: isFiltered ? 'Sin resultados' : 'Aún no hay proyectos',
        subtitle: isFiltered
            ? 'Intenta con otro término de búsqueda'
            : 'Los proyectos aparecerán aquí pronto.',
        icon: isFiltered
            ? Icons.search_off_rounded
            : Icons.folder_open_rounded,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(showcaseProvider.notifier).load(refresh: true),
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      backgroundColor:
          isDark ? AppColors.darkSurface2 : AppColors.lightSecondary,
      child: ListView.builder(
        padding: const EdgeInsets.only(
            top: 0, bottom: AppSpacing.sp64 + AppSpacing.sp24),
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
              onTap: () => context.push('/project/${project.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletons(bool isDark) {
    return const SizedBox.shrink(); // loading handled inline
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
    _fade =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BioSkeleton(height: 12, radius: AppRadius.xs),
                        const SizedBox(height: 5),
                        BioSkeleton(
                            width: 60, height: 10, radius: AppRadius.xs),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  BioSkeleton(width: 70, height: 22, radius: AppRadius.full),
                ],
              ),
            ),
            // Cover skeleton — 16:9
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BioSkeleton(height: double.infinity, radius: 0),
            ),
            // Footer skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BioSkeleton(height: 14, radius: AppRadius.xs),
                  const SizedBox(height: 6),
                  BioSkeleton(
                      width: double.infinity * 0.75,
                      height: 11,
                      radius: AppRadius.xs),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (_) => Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: BioSkeleton(
                                width: 14,
                                height: 14,
                                radius: AppRadius.full),
                          ),
                        ),
                      ),
                      const Spacer(),
                      BioSkeleton(width: 55, height: 11, radius: AppRadius.xs),
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
