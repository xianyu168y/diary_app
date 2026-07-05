import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/todo_task.dart';
import '../../lib/features/export/export_service.dart';
import '../repositories/fake_todo_repository.dart';

void main() {
  group('ExportService', () {
    test('导出空的待办列表返回 []', () async {
      final service = ExportService(todoRepository: FakeTodoRepository());
      final json = await service.exportTodos();
      expect(jsonDecode(json), []);
    });

    test('导出包含任务的 JSON 包含对应字段', () async {
      final repo = FakeTodoRepository();
      await repo.save(TodoTask(id: '2', title: '写测试', createdAt: DateTime(2026, 7, 2)));
      await repo.save(TodoTask(id: '1', title: '学习 Flutter', createdAt: DateTime(2026, 7, 1)));

      final service = ExportService(todoRepository: repo);
      final json = await service.exportTodos();

      final decoded = jsonDecode(json) as List;
      expect(decoded.length, 2);
      // 按 createdAt 降序，最新的在前
      expect(decoded[0]['title'], '写测试');
      expect(decoded[1]['title'], '学习 Flutter');
    });

    test('导出 JSON 中每个任务都包含必要字段', () async {
      final repo = FakeTodoRepository();
      await repo.save(TodoTask(
        id: '1', title: '完整任务', priority: 2, isDone: true,
        createdAt: DateTime(2026, 7, 1),
      ));

      final service = ExportService(todoRepository: repo);
      final json = await service.exportTodos();
      final decoded = jsonDecode(json)[0] as Map;

      expect(decoded['id'], '1');
      expect(decoded['title'], '完整任务');
      expect(decoded['priority'], 2);
      expect(decoded['isDone'], true);
      expect(decoded['createdAt'], isNotNull);
      expect(decoded['totalFocusMinutes'], 0);
    });
  });
}