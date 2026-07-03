import 'package:hive/hive.dart';
import '../models/todo_task.dart';

class TodoService {
  static const String _boxName = 'todo_box';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<TodoTask> getAll() {
    final values = _box.values.cast<Map>().toList();
    final tasks = values.map((m) => TodoTask.fromMap(Map<String, dynamic>.from(m))).toList();
    // 排序：优先级高>中>低 > 创建时间倒序，已完成排在最后
    tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });
    return tasks;
  }

  Future<void> save(TodoTask task) async {
    await _box.put(task.id, task.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}