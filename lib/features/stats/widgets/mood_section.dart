import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../models/diary_entry.dart';

const _moodLabels = {'happy': '😊 开心', 'plain': '😐 平淡', 'tired': '😴 疲惫', 'sad': '😢 难过', 'excited': '🤩 兴奋'};
const _moodColors = {'happy': Color(0xFFFFE4B5), 'plain': Color(0xFFE0E0E0), 'tired': Color(0xFFBDBDBD), 'sad': Color(0xFFBBDEFB), 'excited': Color(0xFFFFF9C4)};
const _defaultColor = Color(0xFFF5F5F5);

class MoodSection extends StatelessWidget {
  final List<DiaryEntry> entries;

  const MoodSection({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final dayMoods = <int, String>{};
    for (final e in entries) {
      dayMoods[e.createdAt.day] = e.mood!;
    }
    final moodCounts = <String, int>{};
    for (final e in entries) {
      moodCounts[e.mood!] = (moodCounts[e.mood!] ?? 0) + 1;
    }
    final total = entries.length;

    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return _card(
      context,
      children: [
        const Row(children: [
          Icon(Icons.emoji_emotions_outlined, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('本月心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Column(children: [
            Row(children: ['一','二','三','四','五','六','日'].map((d) => Expanded(child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)))).toList()),
            const SizedBox(height: 4),
            Expanded(child: GridView.count(
              crossAxisCount: 7,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(monthEnd.day, (i) {
                final day = i + 1;
                final mood = dayMoods[day];
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: mood != null ? (_moodColors[mood] ?? _defaultColor) : _defaultColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                );
              }),
            )),
          ]),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: moodCounts.entries.map((e) {
          final pct = (e.value / total * 100).round();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: (_moodColors[e.key] ?? _defaultColor).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
            child: Text('${_moodLabels[e.key] ?? e.key} $pct%', style: const TextStyle(fontSize: 11, color: AppTheme.textBrown)),
          );
        }).toList()),
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