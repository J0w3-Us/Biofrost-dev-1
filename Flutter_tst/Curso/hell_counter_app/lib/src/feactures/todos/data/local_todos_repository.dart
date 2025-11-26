import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class LocalTodosRepository {
  static const _kKey = 'todos_collection_v1';

  final SharedPreferences _prefs;

  LocalTodosRepository(this._prefs);

  List<Todo> _loadFromPrefs() {
    final raw = _prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Todo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Todo>> loadTodos() async {
    return _loadFromPrefs();
  }

  Future<void> saveTodos(List<Todo> todos) async {
    final raw = json.encode(todos.map((t) => t.toJson()).toList());
    await _prefs.setString(_kKey, raw);
  }

  Future<void> addOrUpdateTodo(Todo todo) async {
    final todos = _loadFromPrefs();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      todos[index] = todo;
    } else {
      todos.add(todo);
    }
    await saveTodos(todos);
  }

  Future<void> deleteTodo(String id) async {
    final todos = _loadFromPrefs();
    todos.removeWhere((t) => t.id == id);
    await saveTodos(todos);
  }
}
