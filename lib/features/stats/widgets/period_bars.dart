import 'package:flutter/material.dart';
import '../../../app_theme.dart';

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

const _periodColors = [
  Color(0xFFFFF3E0),
  Color(0xFFFFE4B5),
  Color(0xFFFFD699),
  Color(0xFFFFB347),
  Color(0xFFFFA500),
  Color(0xFFE8952E),
  Color(0xFFD4872A),
];

class PeriodBars extends StatelessWidget {
  final List<int> minutes;

  const PeriodBars({
    super.key,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final maxMin = minutes.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: List.generate(_periods.length, (i) {
          final min = minutes[i];
          final ratio = maxMin > 0 ? min / maxMin : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(_periods[i].label,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textBrown, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 22,
                      color: AppTheme.bgColor,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratio > 0.03 ? ratio : 0.03,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _periodColors[i % _periodColors.length],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    min > 0 ? '${min}min' : '',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}