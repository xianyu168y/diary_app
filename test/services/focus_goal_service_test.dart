import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/focus_goal.dart';
import '../../lib/services/focus_goal_service.dart';
import '../repositories/goal/fake_goal_repository.dart';

void main() {
  late FakeGoalRepository repo;
  late FocusGoalService service;

  setUp(() async {
    repo = FakeGoalRepository();
    service = FocusGoalService(repository: repo);
    await service.init();
  });

  group('FocusGoalService', () {
    test('init 后 getAll 返回空列表', () {
      expect(service.getAll(), isEmpty);
    });

    test('save 添加新目标', () async {
      final goal = FocusGoal(id: '1', name: '学习 Flutter', deadline: DateTime(2026, 8, 1), targetHours: 10);
      await service.save(goal);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.name, '学习 Flutter');
    });

    test('save 更新已有目标', () async {
      final goal = FocusGoal(id: '1', name: '学习 Flutter', deadline: DateTime(2026, 8, 1), targetHours: 10);
      await service.save(goal);

      final updated = FocusGoal(id: '1', name: '学习 Dart', deadline: DateTime(2026, 8, 1), targetHours: 20);
      await service.save(updated);

      expect(service.getAll().length, 1);
      expect(service.getAll().first.name, '学习 Dart');
      expect(service.getAll().first.targetHours, 20);
    });

    test('delete 后目标消失', () async {
      final goal = FocusGoal(id: '1', name: '待删除', deadline: DateTime(2026, 8, 1), targetHours: 5);
      await service.save(goal);
      expect(service.getAll().length, 1);

      await service.delete('1');
      expect(service.getAll(), isEmpty);
    });

    test('delete 不存在的 id 不报错', () async {
      await service.delete('nonexistent');
      expect(service.getAll(), isEmpty);
    });

    test('save 多个目标各自独立', () async {
      final g1 = FocusGoal(id: '1', name: '目标一', deadline: DateTime(2026, 8, 1), targetHours: 10);
      final g2 = FocusGoal(id: '2', name: '目标二', deadline: DateTime(2026, 9, 1), targetHours: 20);
      await service.save(g1);
      await service.save(g2);

      expect(service.getAll().length, 2);
      expect(service.getAll().map((g) => g.name), containsAll(['目标一', '目标二']));
    });

    test('init 从仓库加载已有数据', () async {
      final goal = FocusGoal(id: '1', name: '已有目标', deadline: DateTime(2026, 8, 1), targetHours: 10);
      await repo.save(goal);

      final svc = FocusGoalService(repository: repo);
      await svc.init();

      expect(svc.getAll().length, 1);
      expect(svc.getAll().first.name, '已有目标');
    });

    test('目标完成后状态独立', () async {
      final goal = FocusGoal(id: '1', name: '学习 Flutter', deadline: DateTime(2026, 8, 1), targetHours: 10, completed: true);
      await service.save(goal);

      expect(service.getAll().first.completed, true);
    });

    test('多个目标可独立删除', () async {
      final g1 = FocusGoal(id: '1', name: '保留', deadline: DateTime(2026, 8, 1), targetHours: 10);
      final g2 = FocusGoal(id: '2', name: '删除', deadline: DateTime(2026, 9, 1), targetHours: 20);
      await service.save(g1);
      await service.save(g2);

      await service.delete('2');
      expect(service.getAll().length, 1);
      expect(service.getAll().first.name, '保留');
    });
  });
}