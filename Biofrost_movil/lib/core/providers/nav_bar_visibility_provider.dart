import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado global de visibilidad de la barra inferior.
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Controlador reutilizable para ocultar/mostrar la barra según dirección de scroll.
class HideOnScrollController {
  HideOnScrollController({this.deltaThreshold = 8.0});

  final double deltaThreshold;
  double _lastOffset = 0.0;

  void attach(ScrollController scrollController, WidgetRef ref) {
    _lastOffset = scrollController.hasClients ? scrollController.offset : 0.0;

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final position = scrollController.position;
      final direction = position.userScrollDirection;
      final offset = position.pixels;
      final delta = (offset - _lastOffset).abs();

      if (delta < deltaThreshold) return;

      // Siempre mostrar cerca del top para facilitar navegación.
      if (offset <= 24) {
        _setVisible(ref, true);
      } else if (direction == ScrollDirection.reverse) {
        _setVisible(ref, false);
      } else if (direction == ScrollDirection.forward) {
        _setVisible(ref, true);
      }

      _lastOffset = offset;
    });
  }

  void reset(WidgetRef ref) {
    _setVisible(ref, true);
  }

  void _setVisible(WidgetRef ref, bool visible) {
    final notifier = ref.read(navBarVisibleProvider.notifier);
    if (notifier.state != visible) {
      notifier.state = visible;
    }
  }
}
