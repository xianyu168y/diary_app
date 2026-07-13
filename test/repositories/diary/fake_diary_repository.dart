import '../../../lib/repositories/diary/diary_repository.dart';
import '../../../lib/models/diary_entry.dart';

/// 基于内存的假日记仓库，不依赖 Hive。
class FakeDiaryRepository implements DiaryRepository {
  final List<DiaryEntry> _storage = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<DiaryEntry>> getAll() async => List.of(_storage)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(DiaryEntry entry) async {
    _storage.removeWhere((e) => e.id == entry.id);
    _storage.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _storage.removeWhere((e) => e.id == id);
  }
}