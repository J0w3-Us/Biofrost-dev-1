// core/providers/connectivity_provider.dart — Estado de conectividad
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream que emite true cuando hay red, false cuando no.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  // Verificación inicial
  final controller = StreamController<bool>();

  connectivity.checkConnectivity().then((results) {
    controller.add(_isConnected(results));
  });

  final sub = connectivity.onConnectivityChanged.listen((results) {
    controller.add(_isConnected(results));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider síncrono: devuelve true si hay conectividad, false si no.
/// Usa el último valor emitido; asume online mientras no se detecte lo contrario.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true, // asumir online hasta confirmar
      );
});

bool _isConnected(List<ConnectivityResult> results) {
  return results.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet ||
      r == ConnectivityResult.vpn);
}
