/// 通用 CRUD 仓库接口。
///
/// 所有业务模块仓库（Todo / Diary / Pomodoro / Goal 等）统一继承此接口，
/// 保证一致的读写契约，避免每个 Repository 重复定义相同的三个方法。
abstract class CrudRepository<T> {
  /// 初始化存储层（Hive openBox / SQLite 建表 等）
  Future<void> init();

  /// 获取全部数据
  Future<List<T>> getAll();

  /// 保存（新增或更新，由实现层决定 upsert 语义）
  Future<void> save(T item);

  /// 根据 id 删除
  Future<void> delete(String id);
}