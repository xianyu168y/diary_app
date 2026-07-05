import 'package:hive/hive.dart';
import '../../models/todo_task.dart';
import 'todo_repository.dart';

/// Hive 实现的 Todo 仓库
class HiveTodoRepository implements TodoRepository {
  static const String _boxName = 'todo_box';
  late final Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<TodoTask>> getAll() async {
    final values = _box.values.cast<Map>().toList();
    final tasks = values.map((m) => TodoTask.fromMap(Map<String, dynamic>.from(m))).toList();
    tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });
    return tasks;
  }

  @override
  Future<void> save(TodoTask task) async {
    await _box.put(task.id, task.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}