// core/router/app_router.dart — GoRouter con guards de auth (Biofrost)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/pages/create_account_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/showcase/pages/showcase_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/project_detail/pages/project_detail_page.dart';
import '../../features/ranking/pages/ranking_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../widgets/shell_scaffold.dart';

// ── Rutas publicas ────────────────────────────────────────────────────────
const _publicRoutes = [
  '/splash',
  '/login',
  '/create-account',
  '/showcase',
  '/project',
  '/ranking'
];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      switch (authState) {
        case AuthLoading():
          return loc == '/splash' ? null : '/splash';

        case AuthUnauthenticated():
          final isPublic = _publicRoutes.any((r) => loc.startsWith(r));
          return isPublic ? null : '/login';

        case AuthAuthenticated(:final isFirstLogin):
          // Si aún necesita completar datos, continuar en /create-account
          if (isFirstLogin && loc != '/create-account') {
            return '/create-account';
          }
          // Si ya completó, salir de las pantallas de auth
          if (!isFirstLogin &&
              (loc == '/login' ||
                  loc == '/splash' ||
                  loc == '/create-account')) {
            return '/showcase';
          }
          return null;

        case AuthError():
          return (loc == '/login' ||
                  loc == '/splash' ||
                  loc == '/create-account')
              ? null
              : '/login';
      }
    },
    routes: [
      // ── Splash ───────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/create-account',
        builder: (context, state) => const CreateAccountPage(),
      ),
      // ── Shell con NavBar ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ShellScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/showcase',
            builder: (context, state) => const ShowcasePage(),
          ),
          GoRoute(
            path: '/project/:id',
            builder: (context, state) => ProjectDetailPage(
              projectId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/ranking',
            builder: (context, state) => const RankingPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
});
