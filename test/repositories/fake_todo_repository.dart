import '../../lib/repositories/todo_repository.dart';
import '../../lib/models/todo_task.dart';

/// 基于内存的假仓库，不依赖 Hive / 文件系统。
/// 用于 [TodoService] 的单测。
class FakeTodoRepository implements TodoRepository {
  final List<TodoTask> _storage = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<TodoTask>> getAll() async => List.of(_storage)
    ..sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });

  @override
  Future<void> save(TodoTask task) async {
    _storage.removeWhere((t) => t.id == task.id);
    _storage.add(task);
  }

  @override
  Future<void> delete(String id) async {
    _storage.removeWhere((t) => t.id == id);
  }
}