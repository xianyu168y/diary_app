import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _boxName = 'diary_box';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<DiaryEntry> getAll() {
    final values = _box.values.cast<Map>().toList();
    final entries = values.map((m) => DiaryEntry.fromMap(Map<String, dynamic>.from(m))).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(DiaryEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) async {
    // 同时删除关联的图片文件
    final raw = _box.get(id);
    if (raw != null) {
      final entry = DiaryEntry.fromMap(Map<String, dynamic>.from(raw));
      for (final path in entry.images) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await _box.delete(id);
  }

  /// 将图片复制到应用内部存储，返回持久化路径
  Future<String> saveImage(String sourcePath, String entryId, int index) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${appDir.path}/diary_images');
    if (!await imgDir.exists()) await imgDir.create(recursive: true);

    final ext = sourcePath.split('.').last.toLowerCase();
    final destPath = '${imgDir.path}/${entryId}_$index.$ext';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// 删除某条日记中未被引用的图片文件（清除孤儿文件）
  Future<void> cleanupOrphanImages(DiaryEntry entry) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${appDir.path}/diary_images');
    if (!await imgDir.exists()) return;

    final savedPaths = entry.images.toSet();
    await for (final file in imgDir.list()) {
      if (file is File && file.path.contains(entry.id)) {
        if (!savedPaths.contains(file.path)) {
          await file.delete();
        }
      }
    }
  }
}