import '../../../models/pomodoro_record.dart';

class StatsData {
  final int todayCount;
  final int todayMinutes;
  final List<PomodoroRecord> todayRecords;
  final Map<String, int> weeklyCounts;
  final List<String> weekLabels;
  final List<int> periodMinutes;

  const StatsData({
    required this.todayCount,
    required this.todayMinutes,
    required this.todayRecords,
    required this.weeklyCounts,
    required this.weekLabels,
    required this.periodMinutes,
  });
}