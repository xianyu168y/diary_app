import '../../core/repository/crud_repository.dart';
import '../../models/todo_task.dart';

/// Todo 数据仓库。
///
/// 业务层不关心底层存储是 Hive/SQLite/API，只依赖此抽象。
abstract class TodoRepository extends CrudRepository<TodoTask> {
  // 继承 CrudRepository 的 init / getAll / save / delete
}