import '../../core/repository/crud_repository.dart';
import '../../models/diary_entry.dart';

abstract class DiaryRepository extends CrudRepository<DiaryEntry> {
  // 继承 CrudRepository 的 init / getAll / save / delete
}