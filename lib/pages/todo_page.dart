import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/category.dart';
import '../models/todo_task.dart';
import '../core/app_dependencies.dart';
import '../services/category_service.dart';
import '../services/todo_service.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback? onPomodoroStart;
  const TodoPage({super.key, this.onPomodoroStart});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoService _service = appDependencies.todoService;
  final CategoryService _catService = CategoryService();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  List<TodoTask> _tasks = [];
  List<Category> _categories = [];
  String? _selectedCategoryId; // null = 全部
  bool _loaded = false;
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await _service.init();
    await _catService.init();
    setState(() {
      _tasks = _service.getAll();
      _categories = _catService.getAll();
      _loaded = true;
    });
  }

  void _refresh() => setState(() {
    _tasks = _service.getAll();
    _categories = _catService.getAll();
    // 移除已被删除的选中项
    _selectedIds.removeWhere((id) => !_tasks.any((t) => t.id == id));
  });

  List<TodoTask> get _filteredTasks {
    if (_selectedCategoryId == null) return _tasks;
    return _tasks.where((t) => t.category == _selectedCategoryId).toList();
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;
    final task = TodoTask(id: const Uuid().v4(), title: title.trim(),
      category: _selectedCategoryId, createdAt: DateTime.now());
    await _service.save(task);
    _inputController.clear(); _refresh();
  }

  Future<void> _toggle(TodoTask task) async {
    if (_isSelecting) {
      _toggleSelection(task.id);
      return;
    }
    task.toggle();
    await _service.save(task);
    // 循环重复
    if (task.isDone && task.repeatType != null) {
      final newTask = TodoTask(id: const Uuid().v4(), title: task.title, category: task.category,
        priority: task.priority, deadline: _nextRepeatDate(task.repeatType!, task.deadline), repeatType: task.repeatType, createdAt: DateTime.now());
      await _service.save(newTask);
    }
    _refresh();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
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

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${_selectedIds.length} 个待办吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppTheme.deleteRed))),
        ],
      ),
    );
    if (confirm != true) return;
    for (final id in _selectedIds.toList()) {
      await _service.delete(id);
    }
    _selectedIds.clear();
    _refresh();
  }

  void _cancelSelection() => setState(() => _selectedIds.clear());

  void _selectAll() => setState(() {
    _selectedIds.addAll(_tasks.map((t) => t.id));
  });

  Future<void> _startPomodoroForTask(TodoTask task) async {
    final pService = appDependencies.pomodoroService;
    await pService.bindToTodo(task.id, task.title);
    widget.onPomodoroStart?.call();
  }

  @override
  void dispose() { _inputController.dispose(); _inputFocusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final active = filtered.where((t) => !t.isDone).toList();
    final done = filtered.where((t) => t.isDone).toList();

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelecting) _cancelSelection();
      },
      child: Scaffold(
        appBar: _isSelecting
            ? AppBar(
                leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancelSelection),
                title: Text('已选 ${_selectedIds.length} 项'),
                actions: [
                  TextButton(onPressed: _selectAll, child: const Text('全选')),
                  IconButton(icon: const Icon(Icons.delete_rounded, color: AppTheme.deleteRed), onPressed: _deleteSelected),
                ],
              )
            : AppBar(title: const Text('✅ 今日待办')),
        body: !_loaded ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        // 分类筛选栏
        _buildCategoryBar(),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primaryYellow.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Row(children: [
            Expanded(child: TextField(controller: _inputController, focusNode: _inputFocusNode,
              decoration: const InputDecoration(hintText: '新增任务...', border: InputBorder.none, contentPadding: EdgeInsets.fromLTRB(18, 14, 12, 14)),
              onSubmitted: _addTask)),
            Padding(padding: const EdgeInsets.only(right: 6), child: IconButton(
              icon: const Icon(Icons.add_circle_rounded), color: AppTheme.accentOrange, iconSize: 36,
              onPressed: () => _addTask(_inputController.text))),
          ]),
        ),
        Expanded(child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ── 空状态插画 ──
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedCategoryId == null ? '今天还没有计划～' : '该分类下暂无任务～',
                  style: const TextStyle(color: AppTheme.textBrown, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCategoryId == null ? '添加一个任务，开始高效的一天' : '试试切换到其他分类看看',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                ),
                if (_selectedCategoryId == null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _inputFocusNode.requestFocus(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('添加第一个任务'),
                  ),
                ],
              ]))
            : ListView(padding: const EdgeInsets.fromLTRB(0, 4, 0, 80), children: [
                ...active.map(_buildTaskTile),
                if (done.isNotEmpty) ...[
                  Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('已完成 (${done.length})',
                    style: const TextStyle(color: AppTheme.doneGreen, fontSize: 14, fontWeight: FontWeight.w600))),
                  ...done.map(_buildTaskTile),
                ],
              ]),
        ),
      ]),
      ),
    );
  }

  Widget _buildTaskTile(TodoTask task) {
    final selected = _selectedIds.contains(task.id);
    final catName = task.category != null ? _catService.findNameById(task.category) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: selected ? 4 : (task.isDone ? 0.5 : 2),
      color: selected ? AppTheme.primaryYellow.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: selected ? const BorderSide(color: AppTheme.accentOrange, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _toggle(task),
        onLongPress: () => _toggleSelection(task.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // 多选模式显示checkbox，否则显示圆点
                if (_isSelecting)
                  Padding(padding: const EdgeInsets.only(right: 8), child: Icon(
                    selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: selected ? AppTheme.accentOrange : AppTheme.textLight, size: 26)),
                // 勾选框
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: task.isDone ? AppTheme.doneGreen : Colors.transparent,
                    border: Border.all(color: task.isDone ? AppTheme.doneGreen : AppTheme.textLight, width: 2)),
                  child: task.isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
                const SizedBox(width: 14),
                Expanded(child: Text(task.title, style: TextStyle(fontSize: 16,
                  color: task.isDone ? AppTheme.textLight : AppTheme.textBrown,
                  decoration: task.isDone ? TextDecoration.lineThrough : null))),
                // 累计专注
                if (task.totalFocusMinutes > 0)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(8)),
                    child: Text('${task.totalFocusMinutes}min', style: const TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)))),
                // 番茄按钮
                GestureDetector(
                  onTap: () => _startPomodoroForTask(task),
                  child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.deleteRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.timer_outlined, size: 18, color: AppTheme.accentOrange)),
                ),
              ]),
              // 分类标签
              if (catName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 42, top: 2, bottom: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(catName, style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 分类筛选栏 ──
  Widget _buildCategoryBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
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
    );
  }

  Widget _categoryChip(String? id, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategoryId == id;
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
    );
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
              onTap: () { Navigator.pop(ctx); _confirmDeleteCategory(cat, taskCount); },
            ),
          ]),
        ),
      ),
    );
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
    );
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
                await _service.save(t);
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
    );
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
              await _service.save(t);
            }
            await _catService.delete(cat.id);
            if (_selectedCategoryId == cat.id) _selectedCategoryId = null;
            _refresh();
            setSheetState(() {});
          },
        ),
      ),
    );
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
    );
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
    );
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
    );
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
    );
  }
}