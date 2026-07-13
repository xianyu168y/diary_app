import 'package:flutter_test/flutter_test.dart';
import '../../../lib/models/todo_task.dart';
import '../../../lib/models/diary_entry.dart';
import '../../../lib/models/pomodoro_record.dart';
import '../../../lib/features/streak/services/streak_service.dart';
import '../../../lib/features/streak/models/streak_data.dart';
import '../../../test/repositories/fake_todo_repository.dart';
import '../../../test/repositories/diary/fake_diary_repository.dart';
import '../../../test/repositories/pomodoro/fake_pomodoro_repository.dart';

void main() {
  late FakeTodoRepository todoRepo;
  late FakeDiaryRepository diaryRepo;
  late FakePomodoroRepository pomoRepo;
  late StreakService service;

  setUp(() {
    todoRepo = FakeTodoRepository();
    diaryRepo = FakeDiaryRepository();
    pomoRepo = FakePomodoroRepository();
    service = StreakService(
      todoRepository: todoRepo,
      diaryRepository: diaryRepo,
      pomodoroRepository: pomoRepo,
    );
  });

  Future<StreakData> calc() => service.calculate();

  group('StreakService', () {
    test('无任何数据时连续天数为 0', () async {
      final result = await calc();
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
    });

    test('未完成的 Todo 不触发学习日', () async {
      await todoRepo.save(TodoTask(id: '1', title: '未完成', createdAt: DateTime.now()));
      final result = await calc();
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
    });

    test('今日完成的 Todo 触发学习日', () async {
      final now = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: '学习', isDone: true, completedAt: now, createdAt: now));
      final result = await calc();
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });

    test('昨日完成的 Todo 不触发今日学习日', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await todoRepo.save(TodoTask(id: '1', title: '昨天完成', isDone: true, completedAt: yesterday, createdAt: yesterday));
      final result = await calc();
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 1);
    });

    test('完成日期早于创建日期的 Todo 按完成日期算', () async {
      final today = DateTime.now();
      final past = today.subtract(const Duration(days: 5));
      await todoRepo.save(TodoTask(id: '1', title: '补完成', isDone: true, completedAt: today, createdAt: past));
      final result = await calc();
      expect(result.currentStreak, 1); // 完成日期是今天
      expect(result.longestStreak, 1);
    });

    test('今日有 Diary 触发学习日', () async {
      await diaryRepo.save(DiaryEntry(id: '1', title: '日记', content: '', createdAt: DateTime.now()));
      final result = await calc();
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });

    test('今日有 Pomodoro 触发学习日', () async {
      final now = DateTime.now();
      await pomoRepo.save(PomodoroRecord(
        id: '1', date: now, startTime: now, endTime: now, minutes: 25,
      ));
      final result = await calc();
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });

    test('连续 3 天有学习记录', () async {
      final today = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: 'Day1', isDone: true, completedAt: today.subtract(const Duration(days: 2)), createdAt: today.subtract(const Duration(days: 2))));
      await diaryRepo.save(DiaryEntry(id: '2', title: 'Day2', content: '', createdAt: today.subtract(const Duration(days: 1))));
      await pomoRepo.save(PomodoroRecord(
        id: '3', date: today, startTime: today, endTime: today, minutes: 25,
      ));

      final result = await calc();
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('过去连续学习但今天没学 → currentStreak 为 0', () async {
      final today = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: 'd-3', isDone: true, completedAt: today.subtract(const Duration(days: 3)), createdAt: today.subtract(const Duration(days: 3))));
      await todoRepo.save(TodoTask(id: '2', title: 'd-2', isDone: true, completedAt: today.subtract(const Duration(days: 2)), createdAt: today.subtract(const Duration(days: 2))));
      await todoRepo.save(TodoTask(id: '3', title: 'd-1', isDone: true, completedAt: today.subtract(const Duration(days: 1)), createdAt: today.subtract(const Duration(days: 1))));

      final result = await calc();
      expect(result.currentStreak, 0);  // 今天没学
      expect(result.longestStreak, 3);  // 过去连续 3 天
    });

    test('中断后重新开始，currentStreak 从今天算起', () async {
      final today = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: 'd-4', isDone: true, completedAt: today.subtract(const Duration(days: 4)), createdAt: today.subtract(const Duration(days: 4))));
      await todoRepo.save(TodoTask(id: '2', title: 'd-3', isDone: true, completedAt: today.subtract(const Duration(days: 3)), createdAt: today.subtract(const Duration(days: 3))));
      await todoRepo.save(TodoTask(id: '3', title: 'today', isDone: true, completedAt: today, createdAt: today));

      final result = await calc();
      expect(result.currentStreak, 1);  // 只连续到今天（昨天中断）
      expect(result.longestStreak, 2);  // 第3-4天连续2天
    });

    test('longestStreak 记录最长连续段', () async {
      final today = DateTime.now();
      for (int i = 10; i >= 6; i--) {
        final d = today.subtract(Duration(days: i));
        await todoRepo.save(TodoTask(id: 'long-$i', title: 'long', isDone: true, completedAt: d, createdAt: d));
      }
      for (int i = 2; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        await todoRepo.save(TodoTask(id: 'short-$i', title: 'short', isDone: true, completedAt: d, createdAt: d));
      }

      final result = await calc();
      expect(result.currentStreak, 3);   // 最近连续3天
      expect(result.longestStreak, 5);   // 最长连续5天
    });

    test('多来源同一天不重复计数', () async {
      final today = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: '学习', isDone: true, completedAt: today, createdAt: today));
      await diaryRepo.save(DiaryEntry(id: '2', title: '日记', content: '', createdAt: today));
      await pomoRepo.save(PomodoroRecord(id: '3', date: today, startTime: today, endTime: today, minutes: 25));

      final result = await calc();
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });

    test('昨天和今天连续', () async {
      final today = DateTime.now();
      await todoRepo.save(TodoTask(id: '1', title: '昨天', isDone: true, completedAt: today.subtract(const Duration(days: 1)), createdAt: today.subtract(const Duration(days: 1))));
      await todoRepo.save(TodoTask(id: '2', title: '今天', isDone: true, completedAt: today, createdAt: today));

      final result = await calc();
      expect(result.currentStreak, 2);
      expect(result.longestStreak, 2);
    });
  });
}