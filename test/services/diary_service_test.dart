import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/diary_entry.dart';
import '../../lib/services/diary_service.dart';
import '../repositories/diary/fake_diary_repository.dart';

void main() {
  late FakeDiaryRepository repo;
  late DiaryService service;

  setUp(() async {
    repo = FakeDiaryRepository();
    service = DiaryService(repository: repo);
    await service.init();
  });

  group('DiaryService', () {
    test('init 后 getAll 返回空列表', () {
      expect(service.getAll(), isEmpty);
    });

    test('save 添加新日记', () async {
      final entry = DiaryEntry(id: '1', title: '测试日记', content: '内容', createdAt: DateTime.now());
      await service.save(entry);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.title, '测试日记');
      expect(service.getAll().first.content, '内容');
    });

    test('save 更新已有日记', () async {
      final entry = DiaryEntry(id: '1', title: '原标题', content: '原内容', createdAt: DateTime.now());
      await service.save(entry);

      final updated = DiaryEntry(id: '1', title: '新标题', content: '新内容', createdAt: entry.createdAt);
      await service.save(updated);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.title, '新标题');
      expect(service.getAll().first.content, '新内容');
    });

    test('delete 后日记消失', () async {
      final entry = DiaryEntry(id: '1', title: '待删除', content: '', createdAt: DateTime.now());
      await service.save(entry);
      expect(service.getAll().length, 1);

      await service.delete('1');
      expect(service.getAll(), isEmpty);
    });

    test('日记按创建时间倒序排列', () async {
      final older = DiaryEntry(id: '1', title: '旧的', content: '', createdAt: DateTime(2026, 7, 1));
      final newer = DiaryEntry(id: '2', title: '新的', content: '', createdAt: DateTime(2026, 7, 2));
      await service.save(older);
      await service.save(newer);

      expect(service.getAll().first.id, '2'); // 新的在前
      expect(service.getAll().last.id, '1');  // 旧的在后
    });

    test('init 从仓库加载已有数据', () async {
      final entry = DiaryEntry(id: '1', title: '已有日记', content: '', createdAt: DateTime.now());
      await repo.save(entry);

      final svc = DiaryService(repository: repo);
      await svc.init();

      expect(svc.getAll().length, 1);
      expect(svc.getAll().first.title, '已有日记');
    });

    test('delete 删除不存在的 id 不报错', () async {
      await service.delete('nonexistent');
      expect(service.getAll(), isEmpty);
    });

    test('save 包含 mood 字段', () async {
      final entry = DiaryEntry(id: '1', title: '心情日记', content: '', mood: 'happy', createdAt: DateTime.now());
      await service.save(entry);

      expect(service.getAll().first.mood, 'happy');
    });

    test('save 包含 tags 和 images', () async {
      final entry = DiaryEntry(id: '1', title: '完整日记', content: '完整内容',
        tags: ['flutter', 'test'], images: ['img1.png', 'img2.png'],
        createdAt: DateTime.now());
      await service.save(entry);

      final saved = service.getAll().first;
      expect(saved.tags, ['flutter', 'test']);
      expect(saved.images, ['img1.png', 'img2.png']);
    });
  });
}