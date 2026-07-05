import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../models/streak_data.dart';

/// 连续学习天数展示卡片。
class StreakCard extends StatelessWidget {
  final StreakData data;
  final bool isLoading;

  const StreakCard({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _card(
        context,
        child: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    return _card(
      context,
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已连续学习',
                  style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFA89F91) : AppTheme.textLight)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${data.currentStreak}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                    const SizedBox(width: 4),
                    Text('天',
                      style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('历史最长',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA89F91) : AppTheme.textLight)),
              const SizedBox(height: 2),
              Text('${data.longestStreak} 天',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isDark ? Colors.black : AppTheme.primaryYellow).withValues(alpha: 0.3),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}