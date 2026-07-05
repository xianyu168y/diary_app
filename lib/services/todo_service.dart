import '../models/todo_task.dart';
import '../repositories/todo_repository.dart';
import '../repositories/hive_todo_repository.dart';

/// 待办业务层。
///
/// 职责：
/// - 启动时从 [TodoRepository] 加载数据到内存缓存
/// - 提供同步的 [getAll] 查询（避免调用方到处 async）
/// - 写入操作委托给 [repository] 并同步更新缓存
///
/// 构造时可注入自定义 [repository] 用于测试，默认使用 [HiveTodoRepository]。
class TodoService {
  final TodoRepository _repository;
  List<TodoTask> _tasks = [];

  TodoService({TodoRepository? repository})
    : _repository = repository ?? HiveTodoRepository();

  /// 初始化存储层，加载全量数据到内存
  Future<void> init() async {
    await _repository.init();
    _tasks = await _repository.getAll();
  }

  /// 返回内存缓存中的待办（同步）
  List<TodoTask> getAll() => _tasks;

  /// 保存待办，同步更新缓存
  Future<void> save(TodoTask task) async {
    await _repository.save(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    _sort();
  }

  /// 删除待办，同步更新缓存
  Future<void> delete(String id) async {
    await _repository.delete(id);
    _tasks.removeWhere((t) => t.id == id);
  }

  /// 按 未完成优先 → 优先级降序 → 创建时间倒序 排序
  void _sort() {
    _tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}