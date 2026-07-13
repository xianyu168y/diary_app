import 'package:hive/hive.dart';
import '../../models/focus_goal.dart';
import 'goal_repository.dart';

/// Hive 实现的专注目标仓库。
class HiveGoalRepository implements GoalRepository {
  static const String _boxName = 'focus_goal_box';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<FocusGoal>> getAll() async {
    final values = _box.values.cast<Map>().toList();
    return values
        .map((m) => FocusGoal.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> save(FocusGoal goal) async {
    await _box.put(goal.id, goal.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}