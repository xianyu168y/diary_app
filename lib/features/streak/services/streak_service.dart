import '../../../repositories/todo/todo_repository.dart';
import '../../../repositories/diary/diary_repository.dart';
import '../../../repositories/pomodoro/pomodoro_repository.dart';
import '../../../models/todo_task.dart';
import '../../../models/diary_entry.dart';
import '../../../models/pomodoro_record.dart';
import '../models/streak_data.dart';

/// 连续学习天数计算服务。
///
/// 学习日判断：
/// - Todo：已完成（isDone）且 completedAt 不为空 → 使用 completedAt
/// - Diary：有记录 → 使用 createdAt
/// - Pomodoro：有记录 → 使用 date
///
/// 纯业务逻辑，不依赖 UI 或 Hive。
class StreakService {
  final TodoRepository _todoRepository;
  final DiaryRepository _diaryRepository;
  final PomodoroRepository _pomodoroRepository;

  StreakService({
    required TodoRepository todoRepository,
    required DiaryRepository diaryRepository,
    required PomodoroRepository pomodoroRepository,
  })  : _todoRepository = todoRepository,
        _diaryRepository = diaryRepository,
        _pomodoroRepository = pomodoroRepository;

  /// 计算当前连续天数与历史最长连续天数。
  Future<StreakData> calculate() async {
    final todos = await _todoRepository.getAll();
    final diaries = await _diaryRepository.getAll();
    final pomodoros = await _pomodoroRepository.getAll();

    // 提取所有活动日期（归一化到年月日，去除时间部分）
    final activeDates = <DateTime>{};

    for (final todo in todos) {
      if (todo.isDone && todo.completedAt != null) {
        activeDates.add(_normalizeDate(todo.completedAt!));
      }
    }
    for (final diary in diaries) {
      activeDates.add(_normalizeDate(diary.createdAt));
    }
    for (final record in pomodoros) {
      activeDates.add(_normalizeDate(record.date));
    }

    if (activeDates.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    // 排序后的日期列表
    final sorted = activeDates.toList()..sort();
    final today = _normalizeDate(DateTime.now());

    // 计算最长连续天数
    int longestStreak = 1;
    int currentRun = 1;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        currentRun++;
      } else {
        if (currentRun > longestStreak) longestStreak = currentRun;
        currentRun = 1;
      }
    }
    if (currentRun > longestStreak) longestStreak = currentRun;

    // 计算当前连续天数：从今天向前追溯
    int currentStreak = 0;
    if (activeDates.contains(today)) {
      currentStreak = 1;
      var checkDate = today.subtract(const Duration(days: 1));
      while (activeDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return StreakData(currentStreak: currentStreak, longestStreak: longestStreak);
  }

  /// 归一化到年月日零点，去除时区影响
  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}