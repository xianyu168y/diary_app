import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../models/pomodoro_record.dart';
import '../../../models/todo_task.dart';
import '../../../services/todo_service.dart';

class LogItem extends StatelessWidget {
  final PomodoroRecord record;
  final TodoService todoService;

  const LogItem({
    super.key,
    required this.record,
    required this.todoService,
  });

  @override
  Widget build(BuildContext context) {
    final todoTask = record.categoryId != null
        ? todoService.getAll().cast<TodoTask?>().firstWhere((t) => t?.id == record.categoryId, orElse: () => null)
        : null;
    final timeFmt = DateFormat('HH:mm');
    final timeRange = '${timeFmt.format(record.startTime)}-${timeFmt.format(record.endTime)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('🍅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(timeRange,
            style: const TextStyle(fontSize: 14, color: AppTheme.textBrown, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${record.minutes}min',
              style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (todoTask != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(todoTask.title,
                style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
            ),
        ],
      ),
    );
  }
}