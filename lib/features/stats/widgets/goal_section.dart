import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app_theme.dart';
import '../../../models/focus_goal.dart';
import '../../../services/focus_goal_service.dart';

class GoalSection extends StatelessWidget {
  final List<FocusGoal> goals;
  final double totalHours;
  final FocusGoalService goalService;
  final VoidCallback onGoalChanged;

  const GoalSection({
    super.key,
    required this.goals,
    required this.totalHours,
    required this.goalService,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goals.length < 8)
          GestureDetector(
            onTap: () => _showCreateGoalDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.flag_rounded, size: 18, color: AppTheme.accentOrange),
                  SizedBox(width: 6),
                  Text('新建专注目标', style: TextStyle(fontSize: 14, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('最多创建 8 个专注目标'),
                backgroundColor: AppTheme.accentOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.block_flipped, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('已达上限(8个)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...goals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildGoalCard(context, g),
          )),
        ],
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, FocusGoal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(goal.deadline.year, goal.deadline.month, goal.deadline.day);
    final daysLeft = deadlineDay.difference(today).inDays;
    final achieved = goal.completed || totalHours >= goal.targetHours;
    final progress = goal.targetHours > 0 ? (totalHours / goal.targetHours).clamp(0.0, 1.0) : 0.0;
    final remainingHours = (goal.targetHours - totalHours).clamp(0, double.infinity);

    Color statusColor;
    String statusText;
    if (daysLeft < 0) {
      statusColor = AppTheme.deleteRed;
      statusText = '已超时 ${-daysLeft}天';
    } else if (achieved) {
      statusColor = AppTheme.doneGreen;
      statusText = '目标完成 ✅';
    } else if (daysLeft <= 2) {
      statusColor = AppTheme.accentOrange;
      statusText = '还剩 $daysLeft 天 ⚠️';
    } else {
      statusColor = AppTheme.primaryYellow.withValues(alpha: 0.7);
      statusText = '还剩 $daysLeft 天';
    }
    if (achieved && daysLeft < 0) {
      statusText = '目标完成 ✅';
      statusColor = AppTheme.doneGreen;
    }

    final hoursStr = totalHours.toStringAsFixed(1);
    final remainStr = remainingHours.toStringAsFixed(1);

    return GestureDetector(
      onLongPress: () => _showGoalMenu(context, goal),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2A26) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(goal.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textBrown))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 14,
                color: AppTheme.bgColor,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress > 0.03 ? progress : 0.03,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.7),
                          achieved ? AppTheme.doneGreen : AppTheme.accentOrange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text('已专注 $hoursStr 小时', style: const TextStyle(fontSize: 12, color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (!achieved)
                Text('还差 $remainStr 小时', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final hoursCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.flag_rounded, color: AppTheme.accentOrange, size: 22),
            SizedBox(width: 8),
            Text('新建专注目标', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl, autofocus: true,
                decoration: InputDecoration(labelText: '目标名称', hintText: '例：考前冲刺专注', filled: true, fillColor: AppTheme.bgColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    builder: (_, child) => Theme(data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.accentOrange),
                    ), child: child!),
                  );
                  if (picked != null) setDState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy年MM月dd日').format(selectedDate), style: const TextStyle(fontSize: 15, color: AppTheme.textBrown)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '目标时长', hintText: '输入小时数', suffixText: '小时', filled: true, fillColor: AppTheme.bgColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final hours = int.tryParse(hoursCtrl.text.trim()) ?? 0;
                if (name.isEmpty || hours <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('请填写完整信息'), backgroundColor: AppTheme.deleteRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                Navigator.pop(ctx);
                final goal = FocusGoal(id: const Uuid().v4(), name: name, deadline: selectedDate, targetHours: hours);
                await goalService.save(goal);
                onGoalChanged();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalMenu(BuildContext context, FocusGoal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(goal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown))),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.edit_rounded, color: AppTheme.accentOrange),
              title: const Text('编辑目标', style: TextStyle(fontSize: 15)),
              onTap: () { Navigator.pop(ctx); _showEditGoalDialog(context, goal); },
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.deleteRed),
              title: const Text('删除目标', style: TextStyle(fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('删除目标', style: TextStyle(color: AppTheme.textBrown)),
                    content: Text('确定要删除「${goal.name}」吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
                      TextButton(onPressed: () async {
                        Navigator.pop(dCtx);
                        await goalService.delete(goal.id);
                        onGoalChanged();
                      }, style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed), child: const Text('删除')),
                    ],
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, FocusGoal goal) {
    final nameCtrl = TextEditingController(text: goal.name);
    DateTime selectedDate = goal.deadline;
    final hoursCtrl = TextEditingController(text: goal.targetHours.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.edit_rounded, color: AppTheme.accentOrange, size: 22),
            SizedBox(width: 8),
            Text('编辑目标', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: '目标名称', filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365 * 3)), builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.accentOrange)), child: child!));
                  if (picked != null) setDState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy年MM月dd日').format(selectedDate), style: const TextStyle(fontSize: 15, color: AppTheme.textBrown)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '目标时长', suffixText: '小时', filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final hours = int.tryParse(hoursCtrl.text.trim()) ?? 0;
                if (name.isEmpty || hours <= 0) return;
                Navigator.pop(ctx);
                goal.name = name; goal.deadline = selectedDate; goal.targetHours = hours;
                await goalService.save(goal);
                onGoalChanged();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}