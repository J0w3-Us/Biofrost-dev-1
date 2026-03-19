// core/cache/cache_database.dart — Persistencia local con SQLite (sqflite)
import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton de acceso a la base de datos SQLite local.
///
/// Expone [StreamController]s internos para notificar a los
/// [LocalRepository]s cada vez que un dato es escrito, habilitando
/// el patrón reactivo sin necesitar Isar ni Hive.
class CacheDatabase {
  CacheDatabase._();
  static final CacheDatabase instance = CacheDatabase._();

  Database? _db;

  /// Acceso público a la BD para repositorios especializados (OutboxQueueRepository).
  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> get _database async => database;

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biofrost_cache.db');

    return openDatabase(
      path,
      version: 2, // v1 = cache tables, v2 = outbox_queue
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE projects_cache (
            id         TEXT PRIMARY KEY,
            data       TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE project_detail_cache (
            id         TEXT PRIMARY KEY,
            data       TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE outbox_queue (
            id           TEXT    PRIMARY KEY,
            operation    TEXT    NOT NULL,
            payload      TEXT    NOT NULL,
            project_id   TEXT    NOT NULL,
            status       TEXT    NOT NULL,
            created_at   INTEGER NOT NULL,
            attempts     INTEGER NOT NULL DEFAULT 0,
            last_error   TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migración v1 → v2: agregar tabla outbox_queue
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS outbox_queue (
              id           TEXT    PRIMARY KEY,
              operation    TEXT    NOT NULL,
              payload      TEXT    NOT NULL,
              project_id   TEXT    NOT NULL,
              status       TEXT    NOT NULL,
              created_at   INTEGER NOT NULL,
              attempts     INTEGER NOT NULL DEFAULT 0,
              last_error   TEXT
            )
          ''');
        }
      },
    );
  }

  // ── Streams Reactivos ─────────────────────────────────────────────────────
  //
  // Un StreamController por tipo de dato. Broadcast = múltiples listeners
  // (un Notifier puede abrirse, cerrarse y reabrirse sin perder el stream).

  /// Emite el [Map] del showcase cada vez que [upsertProjects] escribe.
  /// La clave del snapshot es el pageKey (ej. 'page_initial').
  final _projectsController =
      StreamController<({String key, Map<String, dynamic> data})>.broadcast();

  /// Emite el par [id, Map] del detalle cada vez que [upsertDetail] escribe.
  final _detailController =
      StreamController<({String id, Map<String, dynamic> data})>.broadcast();

  /// Stream de showcase filtrado por [pageKey].
  Stream<Map<String, dynamic>> watchProjects(String pageKey) =>
      _projectsController.stream
          .where((event) => event.key == pageKey)
          .map((event) => event.data);

  /// Stream del detalle filtrado por [id].
  Stream<Map<String, dynamic>> watchDetail(String id) =>
      _detailController.stream
          .where((event) => event.id == id)
          .map((event) => event.data);

  // ── Showcase list ──────────────────────────────────────────────────────

  /// Guarda (o reemplaza) la lista de proyectos y emite al stream reactivo.
  Future<void> upsertProjects(String pageKey, Map<String, dynamic> json) async {
    final db = await _database;
    await db.insert(
      'projects_cache',
      {
        'id': pageKey,
        'data': jsonEncode(json),
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Notifica a los listeners reactivos
    if (!_projectsController.isClosed) {
      _projectsController.add((key: pageKey, data: json));
    }
  }

  /// Recupera la lista paginada por [pageKey]. Devuelve null si no existe.
  Future<({Map<String, dynamic> data, int fetchedAt})?> getProjects(
      String pageKey) async {
    final db = await _database;
    final rows = await db.query(
      'projects_cache',
      where: 'id = ?',
      whereArgs: [pageKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      data: jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
      fetchedAt: rows.first['fetched_at'] as int,
    );
  }

  // ── Project detail ─────────────────────────────────────────────────────

  /// Guarda (o reemplaza) el detalle de un proyecto y emite al stream reactivo.
  Future<void> upsertDetail(String id, Map<String, dynamic> json) async {
    final db = await _database;
    await db.insert(
      'project_detail_cache',
      {
        'id': id,
        'data': jsonEncode(json),
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Notifica a los listeners reactivos
    if (!_detailController.isClosed) {
      _detailController.add((id: id, data: json));
    }
  }

  /// Recupera el detalle de un proyecto por [id]. Devuelve null si no existe.
  Future<({Map<String, dynamic> data, int fetchedAt})?> getDetail(
      String id) async {
    final db = await _database;
    final rows = await db.query(
      'project_detail_cache',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      data: jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
      fetchedAt: rows.first['fetched_at'] as int,
    );
  }

  // ── Mantenimiento ──────────────────────────────────────────────────────

  /// Elimina todo el caché local Y la bandeja de salida (logout).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('projects_cache');
    await db.delete('project_detail_cache');
    await db.delete('outbox_queue');
  }
}
