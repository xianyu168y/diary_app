import '../../models/diary_entry.dart';

/// 日记数据仓库抽象层。
abstract class DiaryRepository {
  Future<void> init();

  Future<List<DiaryEntry>> getAll();

  Future<void> save(DiaryEntry entry);

  Future<void> delete(String id);
}