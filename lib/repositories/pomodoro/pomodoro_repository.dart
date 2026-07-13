import '../../core/repository/crud_repository.dart';
import '../../models/pomodoro_record.dart';

abstract class PomodoroRepository extends CrudRepository<PomodoroRecord> {
  // 继承 CrudRepository 的 init / getAll / save / delete
}