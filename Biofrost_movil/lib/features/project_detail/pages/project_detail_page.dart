// features/project_detail/pages/project_detail_page.dart — RF-03+04 (Biofrost)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/project_detail_read_model.dart';
import '../providers/project_detail_provider.dart';
import '../widgets/rubric_evaluation_section.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailProvider(widget.projectId));
    final auth = ref.watch(authStateProvider);
    final isTeacher = auth is AuthAuthenticated && auth.isTeacher;
    final isGuest = auth is AuthAuthenticated && auth.isGuest;
    final currentUserId = auth is AuthAuthenticated ? auth.uid : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Toast listeners
    ref.listen(projectDetailProvider(widget.projectId), (prev, next) {
      if (next.evalSuccess && !(prev?.evalSuccess ?? false)) {
        BioSnackBar.show(context, '✓ Evaluación enviada correctamente',
            BioToastType.success);
      }
      if (next.evalError != null &&
          next.evalError!.isNotEmpty &&
          prev?.evalError != next.evalError) {
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
          onRetry: () => ref
              .read(projectDetailProvider(widget.projectId).notifier)
              .reload(),
        ),
      );
    }

    final project = state.project!;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder: (headerCtx, _) => [
          // ── AppBar + TabBar ───────────────────────────────────────────
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SharePlus.instance.share(
                    ShareParams(text: 'Mira este proyecto: ${project.title}'),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                const Tab(text: 'Proyecto'),
                Tab(
                  text: project.evaluations.isNotEmpty
                      ? 'Evaluaciones (${project.evaluations.length})'
                      : 'Evaluaciones',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Tab 1: Proyecto ────────────────────────────────────────
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  _VideoPitchCard(
                    coverImageUrl: project.coverImageUrl,
                    videoUrl: project.videoUrl,
                    isDark: isDark,
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

                  // PDF download card
                  _Section(
                    title: 'Recursos',
                    isDark: isDark,
                    child: _PdfDownloadCard(
                      projectTitle: project.title,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp40),
                ],
              ),
            ),

            // ── Tab 2: Evaluaciones ────────────────────────────────────
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Evaluation form (docentes e invitados)
                  if (isTeacher || isGuest) ...[
                    _Section(
                      title: isTeacher ? 'Evaluación' : 'Sugerencia',
                      isDark: isDark,
                      child: RubricEvaluationSection(
                          projectId: project.id, isDark: isDark),
                    ),
                    const SizedBox(height: AppSpacing.sp20),
                  ],

                  // Lista de evaluaciones
                  if (project.evaluations.isNotEmpty)
                    _Section(
                      title: 'Evaluaciones (${project.evaluations.length})',
                      isDark: isDark,
                      child: _EvaluationsList(
                        evaluations: project.evaluations,
                        currentUserId: currentUserId,
                        projectId: project.id,
                        isDark: isDark,
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sp40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightMutedFg,
                            ),
                            const SizedBox(height: AppSpacing.sp12),
                            Text(
                              'Sin evaluaciones aún',
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
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sp40),
                ],
              ),
            ),
          ],
        ),
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
        HapticFeedback.lightImpact();
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

class _VideoPitchCard extends StatelessWidget {
  const _VideoPitchCard({
    required this.coverImageUrl,
    required this.videoUrl,
    required this.isDark,
  });

  final String? coverImageUrl;
  final String? videoUrl;
  final bool isDark;

  Future<void> _openVideo(BuildContext context) async {
    HapticFeedback.lightImpact();
    final raw = videoUrl;
    if (raw == null || raw.trim().isEmpty) return;

    final uri = Uri.tryParse(raw.trim());
    if (uri == null) {
      BioSnackBar.show(
        context,
        'URL de video invalida.',
        BioToastType.warning,
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!opened && context.mounted) {
      BioSnackBar.show(
        context,
        'No se pudo abrir el video.',
        BioToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((videoUrl == null || videoUrl!.trim().isEmpty) && 
        (coverImageUrl == null || coverImageUrl!.trim().isEmpty)) {
      return const SizedBox.shrink(); // No media available at all
    }

    final hasVideo = videoUrl != null && videoUrl!.trim().isNotEmpty;

    return BioCard(
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasVideo
                  ? _EmbeddedVideoPlayer(
                      videoUrl: videoUrl,
                      coverImageUrl: coverImageUrl,
                      isDark: isDark,
                      onOpenExternal: () => _openVideo(context),
                    )
                  : CachedNetworkImage(
                      imageUrl: coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightMuted,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightMuted,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightMutedFg,
                          size: 30,
                        ),
                      ),
                    ),
            ),
          ),
          // Badge "VIDEO PITCH"
          if (hasVideo)
            Positioned(
              left: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VIDEO PITCH',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _EmbeddedVideoPlayer extends StatefulWidget {
  const _EmbeddedVideoPlayer({
    required this.videoUrl,
    required this.coverImageUrl,
    required this.isDark,
    required this.onOpenExternal,
  });

  final String? videoUrl;
  final String? coverImageUrl;
  final bool isDark;
  final VoidCallback onOpenExternal;

  @override
  State<_EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<_EmbeddedVideoPlayer> {
  // ── YouTube ──────────────────────────────────────────────────────────────
  YoutubePlayerController? _ytController;

  // ── Native video ─────────────────────────────────────────────────────────
  VideoPlayerController? _nativeController;
  ChewieController? _chewieController;
  bool _isInitializing = false;
  bool _isBuffering = false;
  bool _hasError = false;

  // Guardamos la referencia al listener para poder removerlo en dispose()
  late final VoidCallback _nativeListener;

  static String? _parseYoutubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final exp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  static bool _isNativeVideoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi') ||
        lower.contains('.mkv') ||
        lower.contains('.webm') ||
        lower.contains('drive.google.com') ||
        lower.contains('drive.usercontent.google.com');
  }

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;

    // Rama A: YouTube
    final videoId = _parseYoutubeId(url);
    if (videoId != null && videoId.isNotEmpty) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      return;
    }

    // Rama B: Video nativo (fire-and-forget, no await en initState)
    if (_isNativeVideoUrl(url)) {
      _initNativePlayer(url!);
    }
  }

  Future<void> _initNativePlayer(String url) async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    final normalizedUrl = _normalizeDriveUrl(url);
    final controller = VideoPlayerController.networkUrl(Uri.parse(normalizedUrl));
    _nativeController = controller;

    _nativeListener = () {
      if (!mounted) return;
      final value = controller.value;
      if (value.isBuffering != _isBuffering) {
        setState(() => _isBuffering = value.isBuffering);
      }
    };
    controller.addListener(_nativeListener);

    try {
      await controller.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        placeholder: _buildThumbnail(),
        errorBuilder: (ctx, errorMessage) => _buildErrorUI(),
      );

      setState(() {
        _isInitializing = false;
        _isBuffering = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
    }
  }

  String _normalizeDriveUrl(String url) {
    final driveFilePattern = RegExp(r'drive\.google\.com\/file\/d\/([^\/]+)');
    final match = driveFilePattern.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return url;
  }

  Future<void> _retry() async {
    final url = widget.videoUrl;
    if (url == null) return;

    _chewieController?.dispose();
    _chewieController = null;
    _nativeController?.removeListener(_nativeListener);
    await _nativeController?.dispose();
    _nativeController = null;

    if (!mounted) return;
    setState(() => _hasError = false);
    await _initNativePlayer(url);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _nativeController?.removeListener(_nativeListener);
    _nativeController?.dispose();
    _ytController?.close();
    super.dispose();
  }

  Widget _buildThumbnail() {
    final hasImage =
        widget.coverImageUrl != null && widget.coverImageUrl!.trim().isNotEmpty;
    if (!hasImage) {
      return Container(
        color: widget.isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.coverImageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: widget.isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
      ),
      errorWidget: (_, __, ___) => Container(
        color: widget.isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
        child: Icon(
          Icons.broken_image_outlined,
          color: widget.isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightMutedFg,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 36),
          const SizedBox(height: 8),
          Text(
            'No se pudo reproducir el video',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: widget.isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightMutedFg,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Reintentar',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Rama A: YouTube ───────────────────────────────────────────────────
    if (_ytController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: _ytController!),
        ),
      );
    }

    // ── Rama B: Video nativo (MP4, Drive, etc.) ───────────────────────────
    if (_isNativeVideoUrl(widget.videoUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(),

              if (_isInitializing)
                const ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

              if (_hasError && !_isInitializing)
                ColoredBox(
                  color: (widget.isDark
                          ? AppColors.darkSurface2
                          : AppColors.lightMuted)
                      .withOpacity(0.92),
                  child: _buildErrorUI(),
                ),

              if (_chewieController != null && !_hasError)
                Chewie(controller: _chewieController!),

              if (_isBuffering && _chewieController != null)
                const Positioned(
                  bottom: 48,
                  right: 12,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // ── Rama C: URL desconocida → fallback externo ────────────────────────
    final hasVideo =
        widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty;
    final hasImage = widget.coverImageUrl != null &&
        widget.coverImageUrl!.trim().isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (hasImage)
          Positioned.fill(child: _buildThumbnail())
        else
          Positioned.fill(
            child: Container(
              color: widget.isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
            ),
          ),
        
        if (hasVideo)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenExternal();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
      ],
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

// ── Evaluation Section has been moved to features/project_detail/widgets/rubric_evaluation_section.dart ──

// ── Evaluaciones List ──────────────────────────────────────────────────────

class _EvaluationsList extends ConsumerWidget {
  const _EvaluationsList({
    required this.evaluations,
    required this.currentUserId,
    required this.projectId,
    required this.isDark,
  });

  final List<EvaluationReadModel> evaluations;
  final String? currentUserId;
  final String projectId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mostrar: las públicas + la propia del usuario (aunque sea privada)
    final visible = evaluations
        .where((e) => e.esPublico || e.evaluatorId == currentUserId)
        .toList();

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Aún no hay evaluaciones públicas',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
          ),
        ),
      );
    }

    return Column(
      children: visible
          .map((e) => _EvalCard(
                eval: e,
                isOwn: e.evaluatorId == currentUserId,
                projectId: projectId,
                isDark: isDark,
              ))
          .toList(),
    );
  }
}

class _EvalCard extends ConsumerWidget {
  const _EvalCard({
    required this.eval,
    required this.isOwn,
    required this.projectId,
    required this.isDark,
  });

  final EvaluationReadModel eval;
  final bool isOwn;
  final String projectId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.evaluatorName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eval.tipo == 'oficial' ? 'Docente' : 'Sugerencia',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: eval.tipo == 'oficial'
                            ? AppColors.info
                            : AppColors.lightOlive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Estrellas
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < (eval.weightedTotalScore / 20).round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppColors.warning,
                  );
                }),
              ),
              // Visibility toggle (solo para el autor)
              if (isOwn) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(projectDetailProvider(projectId).notifier)
                        .toggleVisibility(eval.id, !eval.esPublico);
                  },
                  child: Tooltip(
                    message: eval.esPublico ? 'Hacer privada' : 'Hacer pública',
                    child: Icon(
                      eval.esPublico
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: eval.esPublico ? AppColors.success : textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Feedback removed
          // Visibilidad tag (solo para el autor cuando es privada)
          if (isOwn && !eval.esPublico) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: textSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Privada — solo tú la ves',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
