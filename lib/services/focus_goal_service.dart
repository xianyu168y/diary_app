import 'package:hive/hive.dart';
import '../models/focus_goal.dart';

class FocusGoalService {
  static const String _boxName = 'focus_goal_box';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<FocusGoal> getAll() {
    final values = _box.values.cast<Map>().toList();
    return values
        .map((m) => FocusGoal.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> save(FocusGoal goal) async {
    await _box.put(goal.id, goal.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}