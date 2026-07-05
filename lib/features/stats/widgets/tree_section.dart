import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class TreeSection extends StatelessWidget {
  final int totalCount;
  final int totalMinutes;

  const TreeSection({
    super.key,
    required this.totalCount,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = totalMinutes / 60.0;

    String tree;
    String level;
    if (totalCount >= 100) { tree = '🌸'; level = '樱花林'; }
    else if (totalCount >= 50) { tree = '🍒'; level = '果树园'; }
    else if (totalCount >= 30) { tree = '🌳'; level = '大树'; }
    else if (totalCount >= 10) { tree = '🌿'; level = '小树苗'; }
    else { tree = '🌱'; level = '种子'; }

    return _card(
      context,
      children: [
        const Row(children: [
          Icon(Icons.forest_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('我的小树林', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(tree, style: const TextStyle(fontSize: 48)),
        ]),
        const SizedBox(height: 4),
        Center(child: Text(level, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.accentOrange))),
        const SizedBox(height: 8),
        Center(child: Text('累计完成 $totalCount 个番茄 · ${totalHours.toStringAsFixed(1)} 小时', style: const TextStyle(fontSize: 12, color: AppTheme.textLight))),
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