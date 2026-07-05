import 'dart:convert';
import '../../repositories/todo/todo_repository.dart';
import '../../repositories/diary/diary_repository.dart';
import '../../repositories/pomodoro/pomodoro_repository.dart';
import '../../repositories/goal/goal_repository.dart';

/// 数据导出服务。
///
/// 统一导出全部业务数据，不感知底层存储实现。
class ExportService {
  final TodoRepository todoRepository;
  final DiaryRepository diaryRepository;
  final PomodoroRepository pomodoroRepository;
  final GoalRepository goalRepository;

  ExportService({
    required this.todoRepository,
    required this.diaryRepository,
    required this.pomodoroRepository,
    required this.goalRepository,
  });

  /// 将所有数据导出为 JSON 字符串
  Future<String> exportAll() async {
    final data = {
      'todos': (await todoRepository.getAll()).map((t) => t.toMap()).toList(),
      'diaries': (await diaryRepository.getAll()).map((d) => d.toMap()).toList(),
      'pomodoros': (await pomodoroRepository.getAll()).map((p) => p.toMap()).toList(),
      'goals': (await goalRepository.getAll()).map((g) => g.toMap()).toList(),
    };
    return jsonEncode(data);
  }
}