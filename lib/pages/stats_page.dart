import 'package:flutter/material.dart';
import '../core/app_dependencies.dart';
import '../models/focus_goal.dart';
import '../services/pomodoro_service.dart';
import '../features/stats/models/stats_data.dart';
import '../features/stats/services/stats_service.dart';
import '../features/stats/widgets/goal_section.dart';
import '../features/stats/widgets/today_card.dart';
import '../features/stats/widgets/period_detail_card.dart';
import '../features/stats/widgets/week_card.dart';
import '../features/stats/widgets/mood_section.dart';
import '../features/stats/widgets/tree_section.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _service = PomodoroService();
  final _goalService = appDependencies.goalService;
  final _diaryService = appDependencies.diaryService;
  final _todoService = appDependencies.todoService;
  final _statsService = StatsService();
  bool _initialized = false;

  late StatsData _stats;
  late List<FocusGoal> _goals;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _goalService.init();
    await _diaryService.init();
    await _todoService.init();
    _stats = _statsService.compute(_service.records);
    _goals = _goalService.getAll();
    _service.addListener(_onChanged);
    setState(() => _initialized = true);
  }

  void _onChanged() {
    if (!mounted) return;
    _stats = _statsService.compute(_service.records);
    setState(() {});
  }

  void _refreshGoals() => setState(() => _goals = _goalService.getAll());

  @override
  void dispose() { _service.removeListener(_onChanged); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final totalMinutes = _service.records.fold<int>(0, (s, r) => s + r.minutes);
    final totalHours = totalMinutes / 60.0;
    final totalCount = _service.records.length;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final moodEntries = _diaryService.getAll().where((e) =>
      e.mood != null && e.createdAt.isAfter(monthStart.subtract(const Duration(days: 1))) && e.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('📊 专注统计')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoalSection(
              goals: _goals,
              totalHours: totalHours,
              goalService: _goalService,
              onGoalChanged: _refreshGoals,
            ),
            const SizedBox(height: 16),
            TodayCard(count: _stats.todayCount, minutes: _stats.todayMinutes),
            const SizedBox(height: 16),
            PeriodDetailCard(
              todayCount: _stats.todayCount,
              periodMinutes: _stats.periodMinutes,
              todayRecords: _stats.todayRecords,
              todoService: _todoService,
            ),
            const SizedBox(height: 16),
            WeekCard(weeklyCounts: _stats.weeklyCounts, labels: _stats.weekLabels),
            const SizedBox(height: 16),
            MoodSection(entries: moodEntries),
            const SizedBox(height: 16),
            TreeSection(totalCount: totalCount, totalMinutes: totalMinutes),
          ],
        ),
      ),
    );
  }
}