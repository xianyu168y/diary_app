import '../repositories/todo/hive_todo_repository.dart';
import '../repositories/diary/hive_diary_repository.dart';
import '../repositories/pomodoro/hive_pomodoro_repository.dart';
import '../repositories/goal/hive_goal_repository.dart';
import '../services/todo_service.dart';
import '../services/diary_service.dart';
import '../services/pomodoro_service.dart';
import '../services/focus_goal_service.dart';
import '../features/export/export_service.dart';
import '../features/streak/services/streak_service.dart';

/// 应用级依赖容器。
///
/// 集中管理所有 Repository 和 Service 的创建与初始化，
/// 避免各页面各自创建、重复 init。
///
/// 使用方式：
///   await appDependencies.init();
///   appDependencies.todoService.getAll();
class AppDependencies {
  // ── Repositories ──
  late final HiveTodoRepository todoRepo;
  late final HiveDiaryRepository diaryRepo;
  late final HivePomodoroRepository pomodoroRepo;
  late final HiveGoalRepository goalRepo;

  // ── Services ──
  late final TodoService todoService;
  late final DiaryService diaryService;
  late final PomodoroService pomodoroService;
  late final FocusGoalService goalService;
  late final ExportService exportService;
  late final StreakService streakService;

  /// 初始化所有 Repository 与 Service（并行加载，减少启动时间）
  Future<void> init() async {
    // 1. 创建仓库实例
    todoRepo = HiveTodoRepository();
    diaryRepo = HiveDiaryRepository();
    pomodoroRepo = HivePomodoroRepository();
    goalRepo = HiveGoalRepository();

    // 2. 并行初始化所有仓库
    await Future.wait([
      todoRepo.init(),
      diaryRepo.init(),
      pomodoroRepo.init(),
      goalRepo.init(),
    ]);

    // 3. 创建业务服务（注入仓库，Repository 不重复 init）
    todoService = TodoService(repository: todoRepo);
    diaryService = DiaryService(repository: diaryRepo);
    pomodoroService = PomodoroService(repository: pomodoroRepo);
    goalService = FocusGoalService(repository: goalRepo);
    exportService = ExportService(
      todoRepository: todoRepo,
      diaryRepository: diaryRepo,
      pomodoroRepository: pomodoroRepo,
      goalRepository: goalRepo,
    );
    streakService = StreakService(
      todoRepository: todoRepo,
      diaryRepository: diaryRepo,
      pomodoroRepository: pomodoroRepo,
    );

    // 4. 并行加载服务数据
    await Future.wait([
      todoService.init(),
      diaryService.init(),
      pomodoroService.init(),
      goalService.init(),
    ]);
  }
}

/// 全局依赖访问点。
///
/// 各页面通过此对象获取已初始化的 Service，
/// 不再自行调用 `XxxService()` 构造。
final AppDependencies appDependencies = AppDependencies();