import '../../models/todo_task.dart';

/// Todo 数据存取抽象层。
///
/// 业务层通过此接口读写数据，不依赖具体存储实现（Hive / 内存 / 云端）。
abstract class TodoRepository {
  /// 初始化存储层（Hive openBox / SQLite 建表等）
  Future<void> init();

  /// 返回所有任务，已按优先级+时间排序
  Future<List<TodoTask>> getAll();

  /// 保存（新增或更新）
  Future<void> save(TodoTask task);

  /// 删除
  Future<void> delete(String id);
}