import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  const SettingsPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2A26) : Colors.white;
    final textMain = isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown;
    final textSec = isDark ? const Color(0xFFA89F91) : AppTheme.textLight;
    final accent = isDark ? const Color(0xFFFFAA33) : AppTheme.accentOrange;
    final divider = isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ 设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        children: [
          // ── 显示 ──
          _section(context, '显示'),
          _section(context, '显示'),
          _card(context, cardBg, child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Icon(themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: accent),
            title: Text('深色模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textMain)),
            subtitle: Text(themeProvider.isDark ? '当前：深色柔和模式' : '当前：浅色暖黄模式', style: TextStyle(fontSize: 12, color: textSec)),
            trailing: Switch.adaptive(
              value: themeProvider.isDark,
              activeTrackColor: accent.withValues(alpha: 0.4),
              activeThumbColor: accent,
              onChanged: (_) => themeProvider.toggle(),
            ),
          )),
          const SizedBox(height: 16),

          // ── 关于 ──
          _section(context, '关于'),
          _card(context, cardBg, child: Column(children: [
            _tile(context, Icons.info_outline_rounded, '版本号', '1.1.0+1', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.description_outlined, '功能说明', '日记、待办、番茄钟、统计、目标', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.privacy_tip_outlined, '数据存储', '所有数据仅存于本机，不上传云端', accent, textMain, textSec),
          ])),
          const SizedBox(height: 16),

          // ── 数据管理 ──
          _section(context, '数据管理'),
          _card(context, cardBg, child: Column(children: [
            _tile(context, Icons.backup_rounded, '备份数据', '导出全部日记/待办/番茄记录', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.restore_rounded, '导入备份', '从备份文件恢复数据', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.delete_sweep_rounded, '清除缓存', '清理临时文件释放空间', accent, textMain, textSec),
          ])),
          const SizedBox(height: 16),

          // ── 特色功能 ──
          _section(context, '特色功能'),
          _card(context, cardBg, child: Column(children: [
            _tile(context, Icons.forest_rounded, '小树成就图鉴', '查看累计番茄解锁的成长树木', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.wallpaper_rounded, '壁纸生成', '生成专注/待办壁纸保存到相册', accent, textMain, textSec),
            Divider(height: 1, indent: 48, color: divider),
            _tile(context, Icons.article_outlined, '日记模板', '学习复盘/一日总结/错题记录', accent, textMain, textSec),
          ])),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(text, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFFFAA33) : const Color(0xFFFFA500),
      )),
    );
  }

  Widget _card(BuildContext context, Color cardBg, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black26 : const Color(0xFFFFE4B5).withValues(alpha: 0.3),
          blurRadius: isDark ? 4 : 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Color accent, Color textMain, Color textSec) {
    return ListTile(
      leading: Icon(icon, color: accent, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, color: textMain)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textSec)),
    );
  }

  void _showPasswordDialog(BuildContext context, ThemeProvider tp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2A26) : Colors.white;
    final textMain = isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tp.hasPassword ? '修改密码' : '设置密码', style: TextStyle(color: textMain)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 4,
            decoration: InputDecoration(labelText: '4位数字密码', hintText: '输入4位数字', filled: true, fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            style: TextStyle(fontSize: 24, color: textMain, letterSpacing: 8),
            textAlign: TextAlign.center,
          ),
          if (tp.hasPassword)
            TextButton(onPressed: () async { await tp.clearPassword(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码已关闭'), backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); },
              child: const Text('关闭密码', style: TextStyle(color: AppTheme.deleteRed))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            onPressed: () async {
              final pwd = ctrl.text.trim();
              if (pwd.length != 4 || int.tryParse(pwd) == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('请输入4位数字'), backgroundColor: AppTheme.deleteRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating));
                return;
              }
              await tp.setPassword(pwd);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码已设置'), backgroundColor: AppTheme.doneGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(tp.hasPassword ? '修改' : '确定'),
          ),
        ],
      ),
    );
  }
}