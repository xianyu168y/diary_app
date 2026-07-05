import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class TodayCard extends StatelessWidget {
  final int count;
  final int minutes;

  const TodayCard({
    super.key,
    required this.count,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    return _card(
      context,
      children: [
        const Row(children: [
          Icon(Icons.wb_sunny_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('今日专注', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statItem('🍅', '$count', '完成个数'),
          Container(width: 1, height: 40, color: AppTheme.primaryYellow.withValues(alpha: 0.4)),
          _statItem('⏱️', '$minutes', '专注分钟'),
        ]),
      ],
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
    ]);
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