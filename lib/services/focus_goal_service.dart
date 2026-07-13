import '../models/focus_goal.dart';
import '../repositories/goal/goal_repository.dart';
import '../repositories/goal/hive_goal_repository.dart';

/// 专注目标业务层。
class FocusGoalService {
  final GoalRepository _repository;
  List<FocusGoal> _goals = [];

  FocusGoalService({GoalRepository? repository})
    : _repository = repository ?? HiveGoalRepository();

  Future<void> init() async {
    _goals = await _repository.getAll();
  }

  List<FocusGoal> getAll() => _goals;

  Future<void> save(FocusGoal goal) async {
    await _repository.save(goal);
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _goals.removeWhere((g) => g.id == id);
  }
}