import 'package:hive/hive.dart';
import '../../models/diary_entry.dart';
import 'diary_repository.dart';

/// Hive 实现的日记仓库。
class HiveDiaryRepository implements DiaryRepository {
  static const String _boxName = 'diary_box';
  late final Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<List<DiaryEntry>> getAll() async {
    final values = _box.values.cast<Map>().toList();
    final entries = values.map((m) => DiaryEntry.fromMap(Map<String, dynamic>.from(m))).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}