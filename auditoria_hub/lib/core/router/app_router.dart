// core/router/app_router.dart — GoRouter con guards de auth (Biofrost)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/showcase/pages/showcase_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/project_detail/pages/project_detail_page.dart';
import '../../features/ranking/pages/ranking_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../widgets/shell_scaffold.dart';

// ── Rutas publicas ────────────────────────────────────────────────────────
const _publicRoutes = [
  '/splash',
  '/login',
  '/register',
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
      final currentLocation = state.matchedLocation;

      // Casos de redirección mejorados:
      switch (authState) {
        case AuthLoading():
          // Durante carga, permitir solo splash
          if (currentLocation != '/splash') return '/splash';
          break;

        case AuthUnauthenticated():
          // Sin autenticar: permitir rutas públicas o redirigir a login
          final isPublic =
              _publicRoutes.any((r) => currentLocation.startsWith(r));
          if (!isPublic) return '/login';
          break;

        case AuthAuthenticated(isFirstLogin: true):
          // Usuario autenticado pero necesita completar perfil
          // Por ahora redirigir a showcase, más adelante implementar complete-profile
          if (currentLocation == '/login' || currentLocation == '/splash') {
            return '/showcase';
          }
          break;

        case AuthAuthenticated():
          // Usuario autenticado y perfil completo
          if (currentLocation == '/login' || currentLocation == '/splash') {
            return '/showcase'; // Dashboard principal
          }
          break;

        case AuthError():
          // Error de autenticación → volver al login
          if (currentLocation != '/login' && currentLocation != '/splash') {
            return '/login';
          }
          break;
      }

      return null; // No hay redirección necesaria
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
        path: '/register',
        builder: (context, state) => const RegisterPage(),
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
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
});
