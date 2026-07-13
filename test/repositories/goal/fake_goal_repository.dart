import '../../../lib/repositories/goal/goal_repository.dart';
import '../../../lib/models/focus_goal.dart';

class FakeGoalRepository implements GoalRepository {
  final List<FocusGoal> _storage = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<FocusGoal>> getAll() async => List.of(_storage);

  @override
  Future<void> save(FocusGoal goal) async {
    _storage.removeWhere((g) => g.id == goal.id);
    _storage.add(goal);
  }

  @override
  Future<void> delete(String id) async {
    _storage.removeWhere((g) => g.id == id);
  }
}