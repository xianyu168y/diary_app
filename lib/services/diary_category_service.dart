import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_category.dart';

class DiaryCategoryService {
  static const String _boxName = 'diary_category_box';
  late Box _box;

  static const List<String> defaultCategories = ['生活', '学习', '日常'];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    if (_box.isEmpty) {
      for (final name in defaultCategories) {
        final cat = DiaryCategory(id: const Uuid().v4(), name: name);
        await _box.put(cat.id, cat.toMap());
      }
    }
  }

  List<DiaryCategory> getAll() {
    final values = _box.values.cast<Map>().toList();
    return values
        .map((m) => DiaryCategory.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> save(DiaryCategory cat) async {
    await _box.put(cat.id, cat.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  String? findNameById(String? id) {
    if (id == null) return null;
    final raw = _box.get(id);
    if (raw == null) return null;
    return DiaryCategory.fromMap(Map<String, dynamic>.from(raw)).name;
  }
}