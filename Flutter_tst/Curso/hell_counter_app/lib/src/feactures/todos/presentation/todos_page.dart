import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/todos_cubit.dart';
import '../data/local_todos_repository.dart';
import '../models/todo.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  /// Open TodosPage from anywhere. This will create the repository and cubit.
  static Future<void> open(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TodosPage()));
  }

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  TodosCubit? _cubit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalTodosRepository(prefs);
      final cubit = TodosCubit(repo);
      await cubit.load();
      if (!mounted) return;
      setState(() {
        _cubit = cubit;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _cubit!,
      child: Scaffold(
        appBar: AppBar(title: const Text('Todos')),
        body: BlocBuilder<TodosCubit, TodosState>(
          builder: (context, state) {
            final todos = state.todos;
            if (todos.isEmpty) return const Center(child: Text('No todos yet'));
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Dismissible(
                  key: Key('todo_${todo.id}'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      context.read<TodosCubit>().delete(todo.id),
                  child: ListTile(
                    title: Text(
                      todo.title,
                      style: todo.isCompleted
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    subtitle: Text(todo.description),
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) =>
                          context.read<TodosCubit>().toggleComplete(todo.id),
                    ),
                    onTap: () async {
                      final edited = await showDialog<Todo>(
                        context: context,
                        builder: (_) => EditTodoDialog(todo: todo),
                      );
                      if (edited != null) {
                        if (!mounted) return;
                        await context.read<TodosCubit>().addOrUpdate(edited);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newTodo = await showDialog<Todo>(
              context: context,
              builder: (_) => const EditTodoDialog(),
            );
            if (newTodo != null) {
              if (!mounted) return;
              await context.read<TodosCubit>().addOrUpdate(newTodo);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class EditTodoDialog extends StatefulWidget {
  final Todo? todo;
  const EditTodoDialog({this.todo, super.key});

  @override
  State<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late final TextEditingController _title;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.todo?.title ?? '');
    _desc = TextEditingController(text: widget.todo?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.todo == null ? 'New Todo' : 'Edit Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final t = Todo(
              id: widget.todo?.id,
              title: _title.text.trim(),
              description: _desc.text.trim(),
              isCompleted: widget.todo?.isCompleted ?? false,
            );
            Navigator.of(context).pop(t);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
