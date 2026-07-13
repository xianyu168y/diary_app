import 'package:intl/intl.dart';
import '../../../models/pomodoro_record.dart';
import '../models/stats_data.dart';

// ── 7 个时段定义 ──
class _Period {
  final String label;
  final int startHour;
  final int endHour;
  const _Period(this.label, this.startHour, this.endHour);
}

const _periods = [
  _Period('凌晨', 0, 6),
  _Period('早晨', 6, 9),
  _Period('上午', 9, 12),
  _Period('午间', 12, 15),
  _Period('下午', 15, 18),
  _Period('晚间', 18, 21),
  _Period('夜晚', 21, 24),
];

class StatsService {
  StatsData compute(List<PomodoroRecord> records) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    int todayCount = 0;
    int todayMinutes = 0;
    final todayRecords = <PomodoroRecord>[];
    final periodMinutes = List.filled(7, 0);

    for (final r in records) {
      if (DateFormat('yyyy-MM-dd').format(r.date) != todayStr) continue;
      todayCount++;
      todayMinutes += r.minutes;
      todayRecords.add(r);

      final hour = r.startTime.hour;
      for (int i = 0; i < _periods.length; i++) {
        if (hour >= _periods[i].startHour && hour < _periods[i].endHour) {
          periodMinutes[i] += r.minutes;
          break;
        }
      }
    }

    // 本周统计（最近7天）
    final weeklyCounts = <String, int>{};
    final weekLabels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('MM-dd').format(d);
      final dayLabel = ['', '一', '二', '三', '四', '五', '六', '日'][d.weekday];
      weekLabels.add('$dayLabel\n$key');
      weeklyCounts[key] = 0;
    }
    for (final r in records) {
      final rKey = DateFormat('MM-dd').format(r.date);
      if (weeklyCounts.containsKey(rKey)) {
        weeklyCounts[rKey] = (weeklyCounts[rKey] ?? 0) + 1;
      }
    }

    return StatsData(
      todayCount: todayCount,
      todayMinutes: todayMinutes,
      todayRecords: todayRecords,
      weeklyCounts: weeklyCounts,
      weekLabels: weekLabels,
      periodMinutes: periodMinutes,
    );
  }
}