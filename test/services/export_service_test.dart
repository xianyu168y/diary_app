import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/todo_task.dart';
import '../../lib/models/diary_entry.dart';
import '../../lib/models/pomodoro_record.dart';
import '../../lib/models/focus_goal.dart';
import '../../lib/features/export/export_service.dart';
import '../repositories/fake_todo_repository.dart';
import '../repositories/diary/fake_diary_repository.dart';
import '../repositories/pomodoro/fake_pomodoro_repository.dart';
import '../repositories/goal/fake_goal_repository.dart';

void main() {
  group('ExportService', () {
    ExportService _makeService({
      FakeTodoRepository? todo,
      FakeDiaryRepository? diary,
      FakePomodoroRepository? pomodoro,
      FakeGoalRepository? goal,
    }) {
      return ExportService(
        todoRepository: todo ?? FakeTodoRepository(),
        diaryRepository: diary ?? FakeDiaryRepository(),
        pomodoroRepository: pomodoro ?? FakePomodoroRepository(),
        goalRepository: goal ?? FakeGoalRepository(),
      );
    }

    test('导出空数据包含四个空列表', () async {
      final service = _makeService();
      final json = await service.exportAll();
      final decoded = jsonDecode(json) as Map;

      expect(decoded['todos'], []);
      expect(decoded['diaries'], []);
      expect(decoded['pomodoros'], []);
      expect(decoded['goals'], []);
    });

    test('导出包含所有类型的数据', () async {
      final todoRepo = FakeTodoRepository();
      final diaryRepo = FakeDiaryRepository();
      final pomoRepo = FakePomodoroRepository();
      final goalRepo = FakeGoalRepository();

      await todoRepo.save(TodoTask(id: 't1', title: '学习 Flutter', createdAt: DateTime(2026, 7, 1)));
      await diaryRepo.save(DiaryEntry(id: 'd1', title: '日记标题', content: '内容', createdAt: DateTime(2026, 7, 2)));
      await pomoRepo.save(PomodoroRecord(
        id: 'p1', date: DateTime(2026, 7, 3),
        startTime: DateTime(2026, 7, 3, 10), endTime: DateTime(2026, 7, 3, 10, 25), minutes: 25,
      ));
      await goalRepo.save(FocusGoal(id: 'g1', name: '目标一', deadline: DateTime(2026, 8, 1), targetHours: 10));

      final service = _makeService(todo: todoRepo, diary: diaryRepo, pomodoro: pomoRepo, goal: goalRepo);
      final json = await service.exportAll();
      final decoded = jsonDecode(json) as Map;

      expect((decoded['todos'] as List).length, 1);
      expect((decoded['diaries'] as List).length, 1);
      expect((decoded['pomodoros'] as List).length, 1);
      expect((decoded['goals'] as List).length, 1);
      expect(decoded['todos'][0]['title'], '学习 Flutter');
      expect(decoded['diaries'][0]['title'], '日记标题');
      expect(decoded['goals'][0]['name'], '目标一');
    });
  });
}