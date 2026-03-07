// core/cache/cache_database.dart — Persistencia local con SQLite (sqflite)
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton de acceso a la base de datos SQLite local.
class CacheDatabase {
  CacheDatabase._();
  static final CacheDatabase instance = CacheDatabase._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biofrost_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE projects_cache (
            id       TEXT PRIMARY KEY,
            data     TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE project_detail_cache (
            id       TEXT PRIMARY KEY,
            data     TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ── Showcase list ──────────────────────────────────────────────────────

  /// Guarda (o reemplaza) la lista paginada de proyectos.
  /// Se almacena todo el JSON de la respuesta bajo la clave [pageKey].
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

  /// Guarda (o reemplaza) el detalle de un proyecto por su [id].
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

  /// Elimina todo el caché local (útil para logout o debug).
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('projects_cache');
    await db.delete('project_detail_cache');
  }
}
