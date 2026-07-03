import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/focus_goal.dart';
import '../models/pomodoro_record.dart';
import '../models/todo_task.dart';
import '../services/diary_service.dart';
import '../services/focus_goal_service.dart';
import '../services/pomodoro_service.dart';
import '../services/todo_service.dart';

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

// ── 7 种黄色系 ──
const _periodColors = [
  Color(0xFFFFF3E0), // 凌晨
  Color(0xFFFFE4B5), // 早晨
  Color(0xFFFFD699), // 上午
  Color(0xFFFFB347), // 午间
  Color(0xFFFFA500), // 下午
  Color(0xFFE8952E), // 晚间
  Color(0xFFD4872A), // 夜晚
];

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final PomodoroService _service = PomodoroService();
  final FocusGoalService _goalService = FocusGoalService();
  final DiaryService _diaryService = DiaryService();
  final TodoService _todoService = TodoService();
  bool _initialized = false;

  int _todayCount = 0;
  int _todayMinutes = 0;
  List<PomodoroRecord> _todayRecords = [];
  Map<String, int> _weeklyCounts = {};
  List<String> _weekLabels = [];
  List<int> _periodMinutes = List.filled(7, 0);
  List<FocusGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _goalService.init();
    await _diaryService.init();
    await _todoService.init();
    _computeStats(_service.records);
    _goals = _goalService.getAll();
    _service.addListener(_onChanged);
    setState(() => _initialized = true);
  }

  void _onChanged() {
    if (mounted) { _computeStats(_service.records); setState(() {}); }
  }

  void _computeStats(List<PomodoroRecord> records) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    _todayCount = 0;
    _todayMinutes = 0;
    _todayRecords = [];
    _periodMinutes = List.filled(7, 0);

    for (final r in records) {
      if (DateFormat('yyyy-MM-dd').format(r.date) != todayStr) continue;
      _todayCount++;
      _todayMinutes += r.minutes;
      _todayRecords.add(r);

      // 按 startTime 归入时段
      final hour = r.startTime.hour;
      for (int i = 0; i < _periods.length; i++) {
        if (hour >= _periods[i].startHour && hour < _periods[i].endHour) {
          _periodMinutes[i] += r.minutes;
          break;
        }
      }
    }

    // 本周统计（最近7天）
    _weeklyCounts = {};
    _weekLabels = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('MM-dd').format(d);
      final dayLabel = ['', '一', '二', '三', '四', '五', '六', '日'][d.weekday];
      _weekLabels.add('$dayLabel\n$key');
      _weeklyCounts[key] = 0;
    }
    for (final r in records) {
      final rKey = DateFormat('MM-dd').format(r.date);
      if (_weeklyCounts.containsKey(rKey)) {
        _weeklyCounts[rKey] = (_weeklyCounts[rKey] ?? 0) + 1;
      }
    }
  }

  @override
  void dispose() { _service.removeListener(_onChanged); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('📊 专注统计')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalSection(),
            const SizedBox(height: 16),
            _buildTodayCard(),
            const SizedBox(height: 16),
            _buildPeriodDetailCard(),
            const SizedBox(height: 16),
            _buildWeekCard(),
            const SizedBox(height: 16),
            _buildMoodSection(),
            const SizedBox(height: 16),
            _buildTreeSection(),
          ],
        ),
      ),
    );
  }

  // ── 今日统计卡片 ──
  Widget _buildTodayCard() {
    return _card(
      children: [
        const Row(children: [
          Icon(Icons.wb_sunny_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('今日专注', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statItem('🍅', '$_todayCount', '完成个数'),
          Container(width: 1, height: 40, color: AppTheme.primaryYellow.withValues(alpha: 0.4)),
          _statItem('⏱️', '$_todayMinutes', '专注分钟'),
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

  // ── 今日时段专注明细卡片 ──
  Widget _buildPeriodDetailCard() {
    return _card(
      children: [
        const Row(children: [
          Icon(Icons.schedule_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 6),
          Text('今日时段专注明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
        ]),
        const SizedBox(height: 16),
        if (_todayCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('今天还没有专注记录哦~\n去番茄钟开始专注吧！',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight, fontSize: 14, height: 1.5)),
            ),
          )
        else ...[
          // 横向柱状图
          _buildPeriodBars(),
          const Divider(height: 24, color: AppTheme.primaryYellow),
          // 明细日志
          ..._todayRecords.reversed.map(_buildLogItem),
        ],
      ],
    );
  }

  // ── 7 时段柱状图 ──
  Widget _buildPeriodBars() {
    final maxMin = _periodMinutes.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: List.generate(_periods.length, (i) {
          final min = _periodMinutes[i];
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
                            border: Border.all(
                              color: AppTheme.accentOrange.withValues(alpha: 0.3),
                            ),
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

  // ── 单条番茄日志 ──
  Widget _buildLogItem(PomodoroRecord record) {
    // 通过 categoryId（存的是绑定待办ID）查任务名
    final todoTask = record.categoryId != null
        ? _todoService.getAll().cast<TodoTask?>().firstWhere((t) => t?.id == record.categoryId, orElse: () => null)
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

  // ── 本周统计卡片（柱状图） ──
  Widget _buildWeekCard() {
    final values = _weeklyCounts.values.toList();
    final totalWeek = values.fold(0, (a, b) => a + b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _card(
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
                          _weekLabels[i].split('\n')[0],
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

  // ── 专注目标模块 ──
  Widget _buildGoalSection() {
    final totalMinutes = _service.records.fold<int>(0, (s, r) => s + r.minutes);
    final totalHours = totalMinutes / 60.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 新建目标按钮
        if (_goals.length < 8)
          GestureDetector(
            onTap: _showCreateGoalDialog,
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
        // 目标卡片列表
        if (_goals.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._goals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildGoalCard(g, totalHours),
          )),
        ],
      ],
    );
  }

  Widget _buildGoalCard(FocusGoal goal, double totalHours) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(goal.deadline.year, goal.deadline.month, goal.deadline.day);
    final daysLeft = deadlineDay.difference(today).inDays;
    final achieved = goal.completed || totalHours >= goal.targetHours;
    final progress = goal.targetHours > 0 ? (totalHours / goal.targetHours).clamp(0.0, 1.0) : 0.0;
    final remainingHours = (goal.targetHours - totalHours).clamp(0, double.infinity);

    // 颜色状态
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
      onLongPress: () => _showGoalMenu(goal),
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
            // 标题行
            Row(children: [
              Expanded(child: Text(goal.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textBrown))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            // 进度条
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
            // 明细文字
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

  void _showCreateGoalDialog() {
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
                await _goalService.save(goal);
                setState(() => _goals = _goalService.getAll());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalMenu(FocusGoal goal) {
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
              onTap: () { Navigator.pop(ctx); _showEditGoalDialog(goal); },
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
                        await _goalService.delete(goal.id);
                        setState(() => _goals = _goalService.getAll());
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

  void _showEditGoalDialog(FocusGoal goal) {
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
                await _goalService.save(goal);
                setState(() => _goals = _goalService.getAll());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 情绪月度日历 ──
  Widget _buildMoodSection() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final entries = _diaryService.getAll().where((e) =>
      e.mood != null && e.createdAt.isAfter(monthStart.subtract(const Duration(days: 1))) && e.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))
    ).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    // 按天分组心情
    final dayMoods = <int, String>{};
    for (final e in entries) {
      dayMoods[e.createdAt.day] = e.mood!;
    }
    // 统计占比
    final moodCounts = <String, int>{};
    for (final e in entries) {
      moodCounts[e.mood!] = (moodCounts[e.mood!] ?? 0) + 1;
    }
    final total = entries.length;

    const moodLabels = {'happy': '😊 开心', 'plain': '😐 平淡', 'tired': '😴 疲惫', 'sad': '😢 难过', 'excited': '🤩 兴奋'};
    const moodColors = {'happy': Color(0xFFFFE4B5), 'plain': Color(0xFFE0E0E0), 'tired': Color(0xFFBDBDBD), 'sad': Color(0xFFBBDEFB), 'excited': Color(0xFFFFF9C4)};
    const defaultColor = Color(0xFFF5F5F5);

    return _card(children: [
      const Row(children: [
        Icon(Icons.emoji_emotions_outlined, color: AppTheme.accentOrange, size: 22),
        SizedBox(width: 6),
        Text('本月心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
      ]),
      const SizedBox(height: 12),
      // 日历网格
      SizedBox(
        height: 140,
        child: Column(children: [
          // 星期头
          Row(children: ['一','二','三','四','五','六','日'].map((d) => Expanded(child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)))).toList()),
          const SizedBox(height: 4),
          // 日期格子（简化版：只显示当月1日到最后一日，按星期对齐）
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
                  color: mood != null ? (moodColors[mood] ?? defaultColor) : defaultColor,
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
      // 占比图例
      Wrap(spacing: 8, runSpacing: 4, children: moodCounts.entries.map((e) {
        final pct = (e.value / total * 100).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: (moodColors[e.key] ?? defaultColor).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
          child: Text('${moodLabels[e.key] ?? e.key} $pct%', style: const TextStyle(fontSize: 11, color: AppTheme.textBrown)),
        );
      }).toList()),
    ]);
  }

  // ── 小树成就系统 ──
  Widget _buildTreeSection() {
    final totalMin = _service.records.fold<int>(0, (s, r) => s + r.minutes);
    final totalHours = totalMin / 60.0;
    final totalCount = _service.records.length;

    // 不同档位解锁不同树木
    String tree;
    String level;
    if (totalCount >= 100) { tree = '🌸'; level = '樱花林'; }
    else if (totalCount >= 50) { tree = '🍒'; level = '果树园'; }
    else if (totalCount >= 30) { tree = '🌳'; level = '大树'; }
    else if (totalCount >= 10) { tree = '🌿'; level = '小树苗'; }
    else { tree = '🌱'; level = '种子'; }

    return _card(children: [
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
    ]);
  }

  // ── 通用卡片 ──
  Widget _card({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppTheme.primaryYellow).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}