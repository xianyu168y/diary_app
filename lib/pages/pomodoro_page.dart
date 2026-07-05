import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/app_dependencies.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> with TickerProviderStateMixin {
  final _service = appDependencies.pomodoroService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    _service.addListener(_onChanged);
    setState(() => _initialized = true);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF2E2A26) : Colors.white;
    final cardBg = isDark ? const Color(0xFF2E2A26) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('🍅 番茄钟')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // 时间选择器（仅在未运行时显示）
            if (!_service.isRunning)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 所有时长按钮
                      ..._service.allDurations.map((m) {
                        final selected = _service.totalSeconds == m * 60;
                        final canDelete = _service.allDurations.length > 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onLongPress: () => _showDurationMenu(m, canDelete),
                            child: ChoiceChip(
                              label: Text('${m}min', style: const TextStyle(fontSize: 12)),
                              selected: selected,
                              selectedColor: AppTheme.accentOrange,
                              backgroundColor: chipBg,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : (isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown),
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (_) => _service.setDuration(m),
                            ),
                          ),
                        );
                      }),
                      // 自定义按钮
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            '${_service.customMinutes}min',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _service.isCustomMode,
                          selectedColor: AppTheme.accentOrange,
                          backgroundColor: chipBg,
                          avatar: const Icon(Icons.edit_rounded, size: 14),
                          labelStyle: TextStyle(
                            color: _service.isCustomMode ? Colors.white : (isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown),
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (_) => _showCustomDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── 绑定待办展示 ──
            if (_service.hasBoundTodo)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3833).withValues(alpha: 0.6) : AppTheme.primaryYellow.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded, size: 16, color: AppTheme.accentOrange),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _service.boundTodoName ?? '',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textBrown, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _service.unbindTodo(),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: AppTheme.deleteRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.deleteRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 圆形进度环
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景圆环
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: 1.0,
                        color: AppTheme.primaryYellow,
                        strokeWidth: 14,
                      ),
                    ),
                  ),
                  // 进度圆环
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _service.progress,
                        color: AppTheme.accentOrange,
                        strokeWidth: 14,
                      ),
                    ),
                  ),
                  // 中间文字
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _service.formattedTime,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _service.isPaused ? '已暂停' : (_service.isRunning ? '专注中' : '准备就绪'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_service.isRunning) ...[
                  // 暂停/继续 + 重置
                  _controlButton(
                    icon: _service.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: _service.isPaused ? '继续' : '暂停',
                    color: AppTheme.accentOrange,
                    onTap: _service.isPaused ? _service.start : _service.pause,
                  ),
                  const SizedBox(width: 20),
                  _controlButton(
                    icon: Icons.stop_rounded,
                    label: '重置',
                    color: AppTheme.deleteRed,
                    onTap: _service.reset,
                  ),
                ] else ...[
                  _controlButton(
                    icon: Icons.play_arrow_rounded,
                    label: '开始',
                    color: AppTheme.doneGreen,
                    onTap: _service.start,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 40),
            // 今日番茄数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.primaryYellow).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🍅', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    '今日完成：${_service.todayCount} 个',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationMenu(int minutes, bool canDelete) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('${minutes}min 操作', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.star_outline_rounded, color: AppTheme.accentOrange),
              title: const Text('设为默认', style: TextStyle(fontSize: 15, color: AppTheme.textBrown)),
              onTap: () async {
                Navigator.pop(ctx);
                await _service.setCustomDuration(minutes);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(Icons.delete_outline_rounded, color: canDelete ? AppTheme.deleteRed : Colors.grey),
              title: Text('删除该时长', style: TextStyle(fontSize: 15, color: canDelete ? AppTheme.textBrown : Colors.grey)),
              enabled: canDelete,
              onTap: canDelete ? () async {
                Navigator.pop(ctx);
                await _service.removeCustomDuration(minutes);
              } : null,
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showCustomDialog() async {
    final controller = TextEditingController(text: _service.customMinutes.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppTheme.accentOrange),
            SizedBox(width: 8),
            Text('自定义时长', style: TextStyle(color: AppTheme.textBrown)),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '分钟数',
            hintText: '输入 1~180',
            suffixText: 'min',
            filled: true,
            fillColor: AppTheme.bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryYellow),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 18, color: AppTheme.textBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val == null || val < 1 || val > 180) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('请输入 1~180 之间的整数'),
                    backgroundColor: AppTheme.deleteRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result >= 1 && result <= 180) {
      await _service.setCustomDuration(result);
      await _service.addCustomDuration(result);
    }
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 圆环绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14159, // 从顶部开始
      2 * 3.14159 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}