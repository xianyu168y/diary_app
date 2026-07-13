import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class CategoryService {
  static const String _boxName = 'category_box';
  late Box _box;

  // 默认分类
  static const List<String> defaultCategories = ['日常', '学习'];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    // 首次启动时写入默认分类
    if (_box.isEmpty) {
      for (final name in defaultCategories) {
        final cat = Category(id: const Uuid().v4(), name: name);
        await _box.put(cat.id, cat.toMap());
      }
    }
  }

  List<Category> getAll() {
    final values = _box.values.cast<Map>().toList();
    return values
        .map((m) => Category.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> save(Category category) async {
    await _box.put(category.id, category.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  String? findNameById(String? id) {
    if (id == null) return null;
    final raw = _box.get(id);
    if (raw == null) return null;
    return Category.fromMap(Map<String, dynamic>.from(raw)).name;
  }
}