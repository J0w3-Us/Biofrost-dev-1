// features/showcase/pages/showcase_page.dart — RF-02: Galería (estilo Biofrost)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
        _scrollCtrl.position.maxScrollExtent - 200) {
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
    final filters = ref.watch(showcaseFiltersProvider);
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = auth is AuthAuthenticated ? auth.displayName : null;
    final techs = _extractTechs(state.projects);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          // ── SliverAppBar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            title: Text(
              userName ?? 'Inicio',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          hintText: 'Buscar proyectos...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ref
                                        .read(showcaseProvider.notifier)
                                        .applyFilter(
                                            filters.copyWith(search: ''));
                                    setState(() {});
                                  },
                                )
                              : null,
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
                    ),
                    // Tech chips
                    if (techs.isNotEmpty)
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: techs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _buildBody(state, filters, isDark),
      ),
    );
  }

  Widget _buildBody(ShowcaseState state, ShowcaseFilters filters, bool isDark) {
    if (state.isLoading) {
      return _buildSkeletons();
    }

    if (state.error != null && state.projects.isEmpty) {
      return BioErrorView(
        message: 'No se pudo cargar los proyectos.\n${state.error}',
        onRetry: () => ref.read(showcaseProvider.notifier).load(),
      );
    }

    if (!state.isLoading && state.projects.isEmpty) {
      final isFiltered = filters.search.isNotEmpty || filters.category != null;
      return BioEmptyView(
        icon: isFiltered ? Icons.search_off_rounded : Icons.folder_open_rounded,
        title: isFiltered ? 'Sin resultados' : 'Sin proyectos',
        subtitle: isFiltered
            ? 'Intenta con otro término de búsqueda'
            : 'Aún no hay proyectos registrados',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(showcaseProvider.notifier).load(refresh: true),
      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      backgroundColor:
          isDark ? AppColors.darkSurface2 : AppColors.lightSecondary,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp12, AppSpacing.sp12, AppSpacing.sp12, AppSpacing.sp24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: state.projects.length + (state.hasMore ? 2 : 0),
        itemBuilder: (ctx, i) {
          if (i >= state.projects.length) {
            return _SkeletonCard(isDark: isDark);
          }
          final project = state.projects[i];
          return ProjectCard(
            project: project,
            onTap: () => context.push('/project/${project.id}'),
          );
        },
      ),
    );
  }

  Widget _buildSkeletons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sp12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(46),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            // Thumbnail area (60%) — con badge placeholders
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BioSkeleton(
                    height: double.infinity,
                    radius: 0,
                  ),
                  // Score badge placeholder — bottom left
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      width: 48,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(80),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  // Badge placeholder — top right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 52,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(80),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info area (40%)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sp10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título line 1
                    BioSkeleton(height: 11, radius: AppRadius.xs),
                    const SizedBox(height: 5),
                    // Título line 2 (más corta)
                    BioSkeleton(
                      width: double.infinity * 0.7,
                      height: 11,
                      radius: AppRadius.xs,
                    ),
                    const Spacer(),
                    // Status dot placeholder
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface3
                                : AppColors.lightMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        BioSkeleton(
                          width: 50,
                          height: 9,
                          radius: AppRadius.xs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
