import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/todo_task.dart';
import '../core/app_dependencies.dart';
import '../services/todo_service.dart';

class TodoPage extends StatefulWidget {
  final VoidCallback? onPomodoroStart;
  const TodoPage({super.key, this.onPomodoroStart});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoService _service = appDependencies.todoService;
  final _inputController = TextEditingController();
  List<TodoTask> _tasks = [];
  bool _loaded = false;
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await _service.init();
    setState(() { _tasks = _service.getAll(); _loaded = true; });
  }

  void _refresh() => setState(() {
    _tasks = _service.getAll();
    // 移除已被删除的选中项
    _selectedIds.removeWhere((id) => !_tasks.any((t) => t.id == id));
  });

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;
    final task = TodoTask(id: const Uuid().v4(), title: title.trim(), createdAt: DateTime.now());
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
  void dispose() { _inputController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = _tasks.where((t) => !t.isDone).toList();
    final done = _tasks.where((t) => t.isDone).toList();

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
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primaryYellow.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Row(children: [
            Expanded(child: TextField(controller: _inputController,
              decoration: const InputDecoration(hintText: '新增任务...', border: InputBorder.none, contentPadding: EdgeInsets.fromLTRB(18, 14, 12, 14)),
              onSubmitted: _addTask)),
            Padding(padding: const EdgeInsets.only(right: 6), child: IconButton(
              icon: const Icon(Icons.add_circle_rounded), color: AppTheme.accentOrange, iconSize: 36,
              onPressed: () => _addTask(_inputController.text))),
          ]),
        ),
        Expanded(child: _tasks.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🎯', style: TextStyle(fontSize: 64)), const SizedBox(height: 12),
                const Text('今天还没有计划~\n添加一个任务吧！', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textLight, fontSize: 16, height: 1.5)),
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
          child: Row(children: [
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
        ),
      ),
    );
  }
}