// lib/core/routing/app_routing.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/login/screen/loggin_screens.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/screens/home_screen.dart';
import 'package:hell_counter_app/src/feactures/auth/aplications/auth_cubit.dart';
import 'package:hell_counter_app/src/feactures/counter/presentation/screens/counter_screen.dart';
import 'package:hell_counter_app/src/feactures/settings/presentation/screens/settings_screen.dart';
import 'package:hell_counter_app/src/feactures/timer/presentation/screens/timer_page.dart';
import 'package:hell_counter_app/src/feactures/todos/presentation/todos_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    routes: <RouteBase>[
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const CounterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/timer', builder: (context, state) => const TimerPage()),
      GoRoute(path: '/todos', builder: (context, state) => const TodosPage()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = context.read<AuthCubit>().state;
      final location = state.matchedLocation;

      // Lista de rutas protegidas
      final protectedRoutes = ['/home', '/counter', '/settings', '/timer'];

      if (authState is! Authenticated && protectedRoutes.contains(location)) {
        return '/login';
      }
      if (authState is Authenticated && location == '/login') {
        return '/home';
      }
      return null;
    },
  );
}
