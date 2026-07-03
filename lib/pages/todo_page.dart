import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/category.dart';
import '../models/todo_task.dart';
import '../services/category_service.dart';
import '../services/pomodoro_service.dart';
import '../services/todo_service.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback? onPomodoroStart;

  const TodoPage({super.key, this.onPomodoroStart});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoService _todoService = TodoService();
  final CategoryService _catService = CategoryService();
  final _inputController = TextEditingController();
  List<TodoTask> _tasks = [];
  List<Category> _categories = [];
  String? _selectedCategoryId; // null = 全部
  bool _loaded = false;

  // 多选模式状态
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _todoService.init();
    await _catService.init();
    setState(() {
      _tasks = _todoService.getAll();
      _categories = _catService.getAll();
      _loaded = true;
    });
  }

  void _refresh() {
    setState(() {
      _tasks = _todoService.getAll();
      _categories = _catService.getAll();
    });
  }

  List<TodoTask> get _filteredTasks {
    if (_selectedCategoryId == null) return _tasks;
    return _tasks.where((t) => t.category == _selectedCategoryId).toList();
  }

  // ── 多选 ──
  void _exitSelectMode() {
    setState(() { _isSelectMode = false; _selectedIds.clear(); });
  }

  void _enterSelectMode(String id) {
    setState(() { _isSelectMode = true; _selectedIds.add(id); });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) { _selectedIds.remove(id); if (_selectedIds.isEmpty) _isSelectMode = false; }
      else { _selectedIds.add(id); }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final filtered = _filteredTasks.map((t) => t.id).toList();
      if (_selectedIds.length == filtered.length && _selectedIds.isNotEmpty) {
        _selectedIds.clear(); _isSelectMode = false;
      } else {
        _selectedIds.addAll(filtered);
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 项吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed), child: const Text('删除')),
        ],
      ),
      ),
    if (confirm == true) {
      for (final id in _selectedIds) { await _todoService.delete(id); }
      _exitSelectMode(); _refresh();
    }
  }

  // ── CRUD ──
  Future<void> _addTask(String title, {int priority = 0, DateTime? deadline}) async {
    if (title.trim().isEmpty) return;
    final task = TodoTask(
      id: const Uuid().v4(), title: title.trim(),
      category: _selectedCategoryId,
      priority: priority,
      deadline: deadline,
      createdAt: DateTime.now(),
      ),
    await _todoService.save(task);
    _inputController.clear();
    _refresh();
  }

  Future<void> _toggle(TodoTask task) async {
    task.toggle();
    await _todoService.save(task);
    // 循环重复：完成后按周期生成下一条
    if (task.isDone && task.repeatType != null) {
      final newTask = TodoTask(
        id: const Uuid().v4(), title: task.title,
        category: task.category, priority: task.priority,
        deadline: _nextRepeatDate(task.repeatType!, task.deadline),
        repeatType: task.repeatType,
        createdAt: DateTime.now(),
      );
      await _todoService.save(newTask);
    }
    _refresh();
  }

  DateTime? _nextRepeatDate(String type, DateTime? original) {
    final now = DateTime.now();
    switch (type) {
      case 'daily': return now.add(const Duration(days: 1));
      case 'weekly': return now.add(const Duration(days: 7));
      case 'monthly': return DateTime(now.year, now.month + 1, now.day);
      default: return original;
    }
  }

  Future<void> _delete(TodoTask task) async {
    await _todoService.delete(task.id);
    _refresh();
  }

  // ── 启动番茄 ──
  Future<void> _startPomodoroForTask(TodoTask task) async {
    final pService = PomodoroService();
    await pService.init();
    await pService.bindToTodo(task.id, task.title);
    widget.onPomodoroStart?.call();
  }

  // ── 长按分类标签菜单 ──
  void _showCategoryChipMenu(String id) {
    final cat = _categories.cast<Category?>().firstWhere((c) => c?.id == id, orElse: () => null);
    if (cat == null) return;
    final taskCount = _tasks.where((t) => t.category == id).length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textBrown))),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.edit_rounded, color: AppTheme.accentOrange),
              title: const Text('编辑分类', style: TextStyle(fontSize: 15)),
              onTap: () { Navigator.pop(ctx); _showRenameCategoryDialog(cat); },
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.deleteRed),
              title: Text('删除分类', style: TextStyle(fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCategory(cat, taskCount);
              },
            ),
          ]),
        ),
      ),
      ),
  }

  void _showRenameCategoryDialog(Category cat) {
    final ctrl = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('编辑分类', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: '输入新名称', filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            onPressed: () async {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) { Navigator.pop(ctx); cat.name = n; await _catService.save(cat); _refresh(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('确定'),
          ),
        ],
      ),
      ),
  }

  void _confirmDeleteCategory(Category cat, int taskCount) {
    final msg = taskCount > 0
        ? '「${cat.name}」下有 $taskCount 个任务，\n删除后任务将移至无分类。'
        : '确定要删除「${cat.name}」吗？';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除分类', style: TextStyle(color: AppTheme.textBrown)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 解绑该分类下的所有任务
              for (final t in _tasks.where((t) => t.category == cat.id)) {
                t.category = null;
                await _todoService.save(t);
              }
              await _catService.delete(cat.id);
              if (_selectedCategoryId == cat.id) _selectedCategoryId = null;
              _refresh();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed),
            child: const Text('删除'),
          ),
        ],
      ),
      ),
  }

  // ── 分类管理弹窗 ──
  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _CategoryManagerSheet(
          categories: _categories,
          taskCounts: _tasks.fold<Map<String, int>>({}, (map, t) {
            if (t.category != null) map[t.category!] = (map[t.category!] ?? 0) + 1;
            return map;
          }),
          onCreated: (name) async {
            final cat = Category(id: const Uuid().v4(), name: name);
            await _catService.save(cat);
            _refresh();
            setSheetState(() {});
          },
          onRenamed: (cat, newName) async {
            cat.name = newName;
            await _catService.save(cat);
            _refresh();
            setSheetState(() {});
          },
          onDeleted: (cat) async {
            for (final t in _tasks.where((t) => t.category == cat.id)) {
              t.category = null;
              await _todoService.save(t);
            }
            await _catService.delete(cat.id);
            if (_selectedCategoryId == cat.id) _selectedCategoryId = null;
            _refresh();
            setSheetState(() {});
          },
        ),
      ),
      ),
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final active = filtered.where((t) => !t.isDone).toList();
    final done = filtered.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: _isSelectMode ? _buildSelectAppBar() : AppBar(title: const Text('✅ 今日待办')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : PopScope(
              canPop: !_isSelectMode,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && _isSelectMode) _exitSelectMode();
              },
              child: Column(
                children: [
                  // ── 分类筛选栏 ──
                  _buildCategoryBar(),

                  // ── 输入区（多选模式下隐藏） ──
                  if (!_isSelectMode) _buildInputArea(),

                  // ── 列表 ──
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🎯', style: TextStyle(fontSize: 64)),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedCategoryId == null
                                      ? '今天还没有计划~\n添加一个任务吧！'
                                      : '该分类下暂无任务~',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.textLight, fontSize: 16, height: 1.5),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(0, 4, 0, _isSelectMode ? 100 : 80),
                            children: [
                              ...active.map(_buildTaskTile),
                              if (done.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                                  child: Text(
                                    '已完成 (${done.length})',
                                    style: const TextStyle(color: AppTheme.doneGreen, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ...done.map(_buildTaskTile),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: _isSelectMode ? _buildBottomBar() : null,
      ),
  }

  // ── 分类筛选栏 ──
  Widget _buildCategoryBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 【全部】
          _categoryChip(null, '全部'),
          ..._categories.map((c) => _categoryChip(c.id, c.name)),
          // 【+新建分类】
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: _showCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppTheme.accentOrange),
                    SizedBox(width: 2),
                    Text('分类', style: TextStyle(fontSize: 12, color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
  }

  Widget _categoryChip(String? id, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategoryId == id;
    // 「全部」标签不可长按
    final canLongPress = id != null;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        onLongPress: canLongPress ? () => _showCategoryChipMenu(id) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentOrange : (isDark ? const Color(0xFF2E2A26) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.accentOrange : (isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : AppTheme.textBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      ),
  }

  // ── 输入区 ──
  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryYellow.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: '新增任务...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(18, 14, 8, 14),
              ),
              onSubmitted: _addTask,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: AppTheme.accentOrange,
              iconSize: 36,
              onPressed: () => _addTask(_inputController.text),
            ),
          ),
        ],
      ),
      ),
  }

  String _deadlineText(DateTime dl) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(dl.year, dl.month, dl.day);
    final diff = dDay.difference(today).inDays;
    if (diff < 0) return '已超时 ${-diff}天 ⚠️';
    if (diff == 0) return '今日截止';
    if (diff == 1) return '明天截止';
    return '剩 $diff 天';
  }
  PreferredSizeWidget _buildSelectAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryYellow,
      foregroundColor: AppTheme.textBrown,
      elevation: 0,
      leadingWidth: 64,
      leading: GestureDetector(
        onTap: _exitSelectMode,
        child: const Center(
          child: Text('取消', style: TextStyle(color: AppTheme.textBrown, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
      title: Text('已选择 ${_selectedIds.length} 项', style: const TextStyle(color: AppTheme.textBrown, fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [
        TextButton(
          onPressed: _toggleSelectAll,
          child: Text(
            _selectedIds.length == _filteredTasks.length ? '取消全选' : '全选',
            style: const TextStyle(color: AppTheme.accentOrange, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
      ),
  }

  // ── 多选模式底部按钮栏 ──
  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomActionBtn(Icons.flag_outlined, '优先级'),
            _bottomActionBtn(Icons.notifications_outlined, '提醒'),
            _bottomActionBtn(
              Icons.delete_outline_rounded, '删除',
              color: _selectedIds.isEmpty ? AppTheme.textLight : AppTheme.deleteRed,
              onTap: _selectedIds.isEmpty ? null : _batchDelete,
            ),
          ],
        ),
      ),
      ),
  }

  Widget _bottomActionBtn(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    final active = color != null || onTap != null;
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label 功能开发中~'), backgroundColor: AppTheme.accentOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? (color ?? AppTheme.accentOrange).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color ?? AppTheme.textBrown, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color ?? AppTheme.textBrown, fontWeight: FontWeight.w500)),
        ]),
      ),
      ),
  }

  // ── 任务卡片 ──
  Widget _buildTaskTile(TodoTask task) {
    final isSelected = _selectedIds.contains(task.id);
    final catName = task.category != null ? _catService.findNameById(task.category) : null;

    // 多选模式
    if (_isSelectMode) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        elevation: isSelected ? 3 : 1,
        color: isSelected ? AppTheme.primaryYellow.withValues(alpha: 0.4) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected ? const BorderSide(color: AppTheme.accentOrange, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleSelect(task.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildCheckCircle(task.isDone),
                const SizedBox(width: 14),
                Expanded(child: _buildTaskText(task)),
                const SizedBox(width: 8),
                _buildSelectCheckbox(isSelected),
              ],
            ),
          ),
        ),
      );
    }

    // 普通模式
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        elevation: task.isDone ? 0.5 : 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggle(task),
          onLongPress: () => _enterSelectMode(task.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCheckCircle(task.isDone),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTaskText(task)),
                    const SizedBox(width: 4),
                    // 累计专注时长
                    if (task.totalFocusMinutes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(8)),
                        child: Text('${task.totalFocusMinutes}min', style: const TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
                      ),
                    // 启动番茄按钮
                    GestureDetector(
                      onTap: () => _startPomodoroForTask(task),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(color: AppTheme.deleteRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.timer_outlined, size: 18, color: AppTheme.accentOrange),
                      ),
                    ),
                  ],
                ),
                // 分类标签
                if (catName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 42, top: 2, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        catName,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
  }

  Widget _buildCheckCircle(bool done) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppTheme.doneGreen : Colors.transparent,
        border: Border.all(color: done ? AppTheme.doneGreen : AppTheme.textLight, width: 2),
      ),
      child: done ? Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
  }

  Widget _buildTaskText(TodoTask task) {
    return Text(
      task.title,
      style: TextStyle(
        fontSize: 16,
        color: task.isDone ? AppTheme.textLight : AppTheme.textBrown,
        decoration: task.isDone ? TextDecoration.lineThrough : null,
        decorationColor: AppTheme.textLight,
      ),
      ),
  }

  Widget _buildSelectCheckbox(bool isSelected) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF4A90D9) : Colors.transparent,
        border: Border.all(color: isSelected ? const Color(0xFF4A90D9) : AppTheme.textLight, width: 2),
      ),
      child: isSelected ? Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
  }
}

// ── 分类管理底部弹窗 ──
class _CategoryManagerSheet extends StatefulWidget {
  final List<Category> categories;
  final Map<String, int> taskCounts;
  final ValueChanged<String> onCreated;
  final void Function(Category, String) onRenamed;
  final ValueChanged<Category> onDeleted;

  const _CategoryManagerSheet({
    required this.categories,
    required this.taskCounts,
    required this.onCreated,
    required this.onRenamed,
    required this.onDeleted,
  });

  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('新建分类', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入分类名称',
            filled: true,
            fillColor: AppTheme.bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                widget.onCreated(name);
                _nameController.clear();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('创建', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      ),
  }

  void _edit(Category cat) {
    final editController = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('重命名分类', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入新名称',
            filled: true,
            fillColor: AppTheme.bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            onPressed: () {
              final name = editController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                widget.onRenamed(cat, name);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      ),
  }

  void _confirmDelete(Category cat) {
    final count = widget.taskCounts[cat.id] ?? 0;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${cat.name}」下有 $count 个任务，不能删除'),
          backgroundColor: AppTheme.accentOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除分类', style: TextStyle(color: AppTheme.textBrown)),
        content: Text('确定要删除「${cat.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); widget.onDeleted(cat); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed),
            child: const Text('删除'),
          ),
        ],
      ),
      ),
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Row(
              children: [
                Icon(Icons.manage_search_outlined, color: AppTheme.accentOrange, size: 20),
                SizedBox(width: 8),
                Text('管理分类', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textBrown)),
              ],
            ),
            const SizedBox(height: 12),
            // 新建按钮
            GestureDetector(
              onTap: _create,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: AppTheme.accentOrange),
                      SizedBox(width: 4),
                      Text('新建分类', style: TextStyle(fontSize: 14, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 分类列表
            ...widget.categories.map((cat) {
              final count = widget.taskCounts[cat.id] ?? 0;
              final canDelete = count == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(cat.name, style: const TextStyle(fontSize: 15, color: AppTheme.textBrown, fontWeight: FontWeight.w500)),
                    ),
                    Text('$count 项', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _edit(cat),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.textBrown),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: canDelete ? () => _confirmDelete(cat) : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('「${cat.name}」下有 $count 个任务，不能删除'),
                            backgroundColor: AppTheme.accentOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: canDelete ? AppTheme.deleteRed.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_rounded, size: 16, color: canDelete ? AppTheme.deleteRed : Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      ),
  }
}