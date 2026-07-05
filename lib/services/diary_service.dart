import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../repositories/diary/diary_repository.dart';
import '../repositories/diary/hive_diary_repository.dart';

/// 日记业务层。
///
/// 职责：
/// - 数据缓存 + 排序
/// - 文件管理（图片复制、孤儿文件清理）
/// - 写入委托给 [DiaryRepository]
///
/// 构造时可注入自定义 [repository] 用于测试，默认使用 [HiveDiaryRepository]。
class DiaryService {
  final DiaryRepository _repository;
  List<DiaryEntry> _entries = [];

  DiaryService({DiaryRepository? repository})
    : _repository = repository ?? HiveDiaryRepository();

  /// 初始化存储层，加载全量数据到内存
  Future<void> init() async {
    await _repository.init();
    _entries = await _repository.getAll();
  }

  /// 返回内存缓存中的日记（同步，按创建时间倒序）
  List<DiaryEntry> getAll() => _entries;

  /// 保存日记，同步更新缓存
  Future<void> save(DiaryEntry entry) async {
    await _repository.save(entry);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 删除日记及关联的图片文件，同步更新缓存
  Future<void> delete(String id) async {
    // 删除关联的图片文件
    final entry = _entries.cast<DiaryEntry?>().firstWhere((e) => e?.id == id, orElse: () => null);
    if (entry != null) {
      for (final path in entry.images) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await _repository.delete(id);
    _entries.removeWhere((e) => e.id == id);
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