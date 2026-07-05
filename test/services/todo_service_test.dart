import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/models/todo_task.dart';
import '../../lib/services/todo_service.dart';
import '../repositories/fake_todo_repository.dart';

void main() {
  late FakeTodoRepository repo;
  late TodoService service;

  setUp(() async {
    repo = FakeTodoRepository();
    service = TodoService(repository: repo);
    await service.init();
  });

  group('TodoService', () {
    test('init 后 getAll 返回空列表', () {
      expect(service.getAll(), isEmpty);
    });

    test('addTask 后 getAll 包含该任务', () async {
      final task = TodoTask(id: const Uuid().v4(), title: '测试任务', createdAt: DateTime.now());
      await service.save(task);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.title, '测试任务');
    });

    test('save 更新已有任务', () async {
      final task = TodoTask(id: '1', title: '原标题', createdAt: DateTime.now());
      await service.save(task);

      final updated = task.copyWith(title: '新标题');
      await service.save(updated);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.title, '新标题');
    });

    test('delete 后任务消失', () async {
      final task = TodoTask(id: '1', title: '待删除', createdAt: DateTime.now());
      await service.save(task);
      expect(service.getAll().length, 1);

      await service.delete('1');
      expect(service.getAll(), isEmpty);
    });

    test('已完成任务排在未完成后面', () async {
      final done = TodoTask(id: '1', title: '已完成', isDone: true, createdAt: DateTime.now());
      final active = TodoTask(id: '2', title: '未完成', createdAt: DateTime.now());
      await service.save(done);
      await service.save(active);

      final tasks = service.getAll();
      expect(tasks.first.id, '2');
      expect(tasks.last.id, '1');
    });

    test('优先级高的排在前面', () async {
      final low = TodoTask(id: '1', title: '低优先级', priority: 0, createdAt: DateTime.now());
      final high = TodoTask(id: '2', title: '高优先级', priority: 2, createdAt: DateTime.now());
      await service.save(low);
      await service.save(high);

      expect(service.getAll().first.id, '2');
    });

    test('init 从仓库加载已有数据', () async {
      final task = TodoTask(id: '1', title: '已有任务', createdAt: DateTime.now());
      await repo.save(task);

      final svc = TodoService(repository: repo);
      await svc.init();

      expect(svc.getAll().length, 1);
      expect(svc.getAll().first.title, '已有任务');
    });
  });
}