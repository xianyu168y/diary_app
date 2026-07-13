import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../models/pomodoro_record.dart';
import '../../../services/todo_service.dart';
import 'period_bars.dart';
import 'log_item.dart';

class PeriodDetailCard extends StatelessWidget {
  final int todayCount;
  final List<int> periodMinutes;
  final List<PomodoroRecord> todayRecords;
  final TodoService todoService;

  const PeriodDetailCard({
    super.key,
    required this.todayCount,
    required this.periodMinutes,
    required this.todayRecords,
    required this.todoService,
  });

  @override
  Widget build(BuildContext context) {
    return _card(
      context,
      children: [
        const Row(children: [
          Icon(Icons.schedule_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('今日时段专注明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 16),
        if (todayCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('今天还没有专注记录哦~\n去番茄钟开始专注吧！',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight, fontSize: 14, height: 1.5)),
            ),
          )
        else ...[
          PeriodBars(minutes: periodMinutes),
          const Divider(height: 24, color: AppTheme.primaryYellow),
          ...todayRecords.reversed.map((r) => LogItem(record: r, todoService: todoService)),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isDark ? Colors.black : AppTheme.primaryYellow).withValues(alpha: 0.3),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}