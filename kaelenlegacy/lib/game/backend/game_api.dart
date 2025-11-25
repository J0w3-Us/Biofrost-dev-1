import 'package:flame/components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Shared small API to avoid circular imports between game and components.
enum GameState { playing, won, intro, gameOver }

abstract class GameApi {
  GameState get gameState;
  double get groundHeight;
  Vector2 get size;
  void onPlayerDied();
}

/// Lightweight Supabase-backed API client used by the game to report
/// events and load level configuration. Methods are defensive and will
/// return sensible fallbacks on error so the game remains playable.
class GameApiClient {
  GameApiClient._();

  static final _client = Supabase.instance.client;

  /// Load level configuration from the `NivelesConfig` table. Returns a
  /// list of obstacle definitions (maps) or an empty list on error.
  static Future<List<dynamic>> loadLevelData(int id) async {
    try {
      final resp = await _client
          .from('NivelesConfig')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (resp == null) return [];
      // Common column names: data / config / obstacles
      final map = resp;
      if (map.containsKey('obstacles') && map['obstacles'] is List) {
        return map['obstacles'] as List<dynamic>;
      }
      if (map.containsKey('data') && map['data'] is List) {
        return map['data'] as List<dynamic>;
      }
      if (map.containsKey('config') && map['config'] is List) {
        return map['config'] as List<dynamic>;
      }
      return [];
    } catch (e, st) {
      // Don't propagate errors to the game loop; just log and fallback.
      debugPrint('⚠️ GameApiClient.loadLevelData error: $e');
      debugPrint('$st');
      return [];
    }
  }

  /// Fire-and-forget call to register a player's death. This intentionally
  /// does not await the RPC so the game thread is not blocked.
  static void recordDeath() {
    try {
      _client.rpc('registrar_muerte_y_contar');
    } catch (e, st) {
      debugPrint('⚠️ GameApiClient.recordDeath error: $e');
      debugPrint('$st');
    }
  }

  /// Mark level complete via RPC. Returns RPC result parsed to int if
  /// available, otherwise null.
  static Future<int?> completeLevel(int id) async {
    try {
      final res = await _client.rpc(
        'completar_seccion',
        params: {'level_id': id},
      );
      if (res is Map && res.containsKey('count')) {
        return (res['count'] as num).toInt();
      }
      if (res is num) return res.toInt();
      return null;
    } catch (e, st) {
      debugPrint('⚠️ GameApiClient.completeLevel error: $e');
      debugPrint('$st');
      return null;
    }
  }
}
