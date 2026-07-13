import '../../core/repository/crud_repository.dart';
import '../../models/focus_goal.dart';

abstract class GoalRepository extends CrudRepository<FocusGoal> {
  // 继承 CrudRepository 的 init / getAll / save / delete
}