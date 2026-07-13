import 'package:hive/hive.dart';
import '../../models/pomodoro_record.dart';
import 'pomodoro_repository.dart';

/// Hive 实现的番茄钟记录仓库。
///
/// 当前存储方式：全部记录序列化为 List<Map> 放入单键 _recordsKey。
/// （与 Todo / Diary 逐个存 key 的方式不同，但对外透明）
class HivePomodoroRepository implements PomodoroRepository {
  static const String _boxName = 'pomodoro_stats';
  static const String _recordsKey = 'records';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<PomodoroRecord>> getAll() async {
    final raw = _box.get(_recordsKey);
    if (raw is! List) return [];
    return raw
        .cast<Map>()
        .map((m) => PomodoroRecord.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> save(PomodoroRecord record) async {
    final records = await getAll();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _box.put(_recordsKey, records.map((r) => r.toMap()).toList());
  }

  @override
  Future<void> delete(String id) async {
    final records = await getAll();
    records.removeWhere((r) => r.id == id);
    await _box.put(_recordsKey, records.map((r) => r.toMap()).toList());
  }
}