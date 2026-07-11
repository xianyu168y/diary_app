import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../services/theme_provider.dart';
import 'diary_editor_page.dart';
import 'diary_page.dart';
import 'todo_page.dart';
import 'pomodoro_page.dart';
import 'stats_page.dart';

const _quotes = [
  '每一个今天，都是你昨天梦想的明天。',
  '坚持不是不累，是累了也不放弃。',
  '你现在的努力，会照亮未来的路。',
  '别怕走得慢，只怕原地踏步。',
  '自律不是约束，是对自己负责。',
  '学习是最好的投资，永远不会贬值。',
  '每一天都是一个新的开始。',
  '不要放弃，今天的努力会在明天开花。',
  '你若盛开，蝴蝶自来。',
  '优秀的人都在你看不见的地方努力。',
  '时间花在哪，成就就在哪。',
  '量变引起质变，坚持就是胜利。',
  '不想被别人否定，就自己更加努力。',
  '路虽远，行则将至。',
  '心有所信，方能行远。',
  '越努力，越幸运。',
  '今天的汗水是明天的勋章。',
  '不要假装很努力，结果不会陪你演戏。',
  '你的坚持，终将美好。',
  '哪怕是最微小的进步，也值得被肯定。',
  '学习的苦是暂时的，不学的苦是一辈子的。',
  '现在的努力，是为了将来有更多的选择。',
  '努力到无能为力，拼搏到感动自己。',
  '别在最好的年纪，辜负最好的自己。',
  '奋斗是青春最亮丽的底色。',
  '每天进步一点点，一年后你将感谢自己。',
  '不要因为没有掌声而放弃梦想。',
  '未来的你，一定会感谢现在拼命的自己。',
  '所有的不甘，都是因为还心存梦想。',
  '与其焦虑未来，不如专注当下。',
  '人生没有白走的路，每一步都算数。',
  '梦想不会发光，发光的是追梦的你。',
  '成功不是终点，失败也不是终结，唯有勇气才是永恒。',
  '你只管努力，剩下的交给时间。',
  '世上没有白费的努力，也没有碰巧的成功。',
  '把努力当成一种习惯，而不是一时兴起。',
  '吃别人吃不了的苦，忍别人忍不了的气，才能得到别人得不到的。',
  '生活不会亏待每一个努力的人。',
  '既然选择了远方，便只顾风雨兼程。',
  '没有横空出世的运气，只有不为人知的努力。',
  '熬过最苦的日子，才能做最酷的自己。',
  '所有的努力都会在某个时刻开花结果。',
  '千万别用年轻时的懒惰和放纵，换一生的后悔和卑微。',
  '不到最后一刻，谁都不知道结局会怎样。',
  '你今天的努力，是未来幸运的伏笔。',
  '今天的不开心就到此为止，明天依然光芒万丈。',
  '要相信，所有的不美好都是为了迎接美好。',
  '当你觉得撑不下去的时候，看看周围，大家都在坚持。',
  '累了就停下来歇歇，但别躺下不走了。',
  '比你优秀的人还在努力，你有什么理由放弃。',
  '不是因为看到希望才坚持，而是坚持了才看到希望。',
  '每一个不曾起舞的日子，都是对生命的辜负。',
  '世界上只有一种真正的英雄主义，那就是在认清生活的真相后依然热爱生活。',
  '敢于背负梦想的人，才配拥有未来。',
  '你的潜力远比你想象的要大得多。',
  '别让将来的你，讨厌现在不努力的自己。',
  '努力的意义，就是以后的日子里，放眼望去全是自己喜欢的人或事。',
  '真正的高手，都是长期主义者。',
  '种一棵树最好的时间是十年前，其次是现在。',
  '耐心和持久胜过激烈和狂热。',
  '所有的成就和美，都伴随着自律和节制。',
];

class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const HomePage({super.key, required this.themeProvider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 延迟检查每日一语，避免干扰首帧渲染
    Future.microtask(_checkAndShowDailyQuote);
  }

  Future<void> _checkAndShowDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final lastShown = prefs.getString('daily_quote_date') ?? '';

    if (lastShown == today) return; // 今天已弹过，跳过

    await prefs.setString('daily_quote_date', today);
    if (mounted) _showDailyQuote(context);
  }

  void _showDailyQuote(BuildContext context) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final quote = _quotes[dayOfYear % _quotes.length];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: AppTheme.accentOrange, size: 22),
          SizedBox(width: 8),
          Text('每日一语', style: TextStyle(color: AppTheme.textBrown, fontWeight: FontWeight.w600)),
        ]),
        content: Text(quote, style: TextStyle(fontSize: 16, height: 1.6, color: Theme.of(context).textTheme.bodyLarge?.color), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭', style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 仅跳转空白日记编辑页，语录不会自动填充
              Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryEditorPage()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('收藏到日记'),
          ),
        ],
      ),
    );
  }

  void _onPomodoroStart() => setState(() => _currentIndex = 2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      DiaryPage(themeProvider: widget.themeProvider),
      TodoPage(onPomodoroStart: _onPomodoroStart),
      const PomodoroPage(),
      const StatsPage(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2A26) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFFFFE4B5).withValues(alpha: 0.4),
            blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: isDark ? const Color(0xFF2E2A26) : Colors.white,
            selectedItemColor: isDark ? const Color(0xFFFFAA33) : const Color(0xFFFFA500),
            unselectedItemColor: isDark ? const Color(0xFFA89F91) : const Color(0xFF9E8E7E),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              _navItem(Icons.menu_book_rounded, '日记'),
              _navItem(Icons.check_circle_rounded, '待办'),
              _navItem(Icons.timer_rounded, '番茄钟'),
              _navItem(Icons.bar_chart_rounded, '统计'),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Semantics(
        label: label,
        child: Icon(icon),
      ),
      label: label,
    );
  }
}