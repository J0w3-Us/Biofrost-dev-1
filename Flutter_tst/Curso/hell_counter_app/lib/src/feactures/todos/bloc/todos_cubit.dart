import 'package:bloc/bloc.dart';
import '../models/todo.dart';
import '../data/local_todos_repository.dart';

class TodosState {
  final List<Todo> todos;
  const TodosState(this.todos);
}

class TodosCubit extends Cubit<TodosState> {
  final LocalTodosRepository _repo;

  TodosCubit(this._repo) : super(const TodosState([]));

  Future<void> load() async {
    final todos = await _repo.loadTodos();
    emit(TodosState(todos));
  }

  Future<void> addOrUpdate(Todo todo) async {
    await _repo.addOrUpdateTodo(todo);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTodo(id);
    await load();
  }

  Future<void> toggleComplete(String id) async {
    final todos = state.todos.map((t) {
      if (t.id == id) return t.copyWith(isCompleted: !t.isCompleted);
      return t;
    }).toList();
    await _repo.saveTodos(todos);
    await load();
  }
}
