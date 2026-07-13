import 'package:flutter/material.dart';
import '../../../app_theme.dart';

const _periodColors = [
  Color(0xFFFFF3E0),
  Color(0xFFFFE4B5),
  Color(0xFFFFD699),
  Color(0xFFFFB347),
  Color(0xFFFFA500),
  Color(0xFFE8952E),
  Color(0xFFD4872A),
];

class WeekCard extends StatelessWidget {
  final Map<String, int> weeklyCounts;
  final List<String> labels;

  const WeekCard({
    super.key,
    required this.weeklyCounts,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final values = weeklyCounts.values.toList();
    final totalWeek = values.fold(0, (a, b) => a + b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _card(
      context,
      children: [
        const Row(children: [
          Icon(Icons.date_range_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('本周统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 4),
        Text('共 $totalWeek 个番茄', style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
        const SizedBox(height: 16),
        if (totalWeek == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('本周还没有专注记录哦~\n去番茄钟开始专注吧！',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight, fontSize: 14, height: 1.5)),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final ratio = maxVal > 0 ? values[i] / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (values[i] > 0)
                          Text('${values[i]}', style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: double.infinity,
                            height: ratio * 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _periodColors[i % _periodColors.length],
                                  _periodColors[(i + 2) % _periodColors.length].withValues(alpha: 0.8),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i].split('\n')[0],
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
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