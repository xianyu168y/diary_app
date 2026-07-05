import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/diary_category.dart';
import '../models/diary_entry.dart';
import '../services/diary_category_service.dart';
import '../services/diary_service.dart';
import '../services/theme_provider.dart';
import 'diary_editor_page.dart';

Color _ct(BuildContext c, Color light, Color dark) =>
    Theme.of(c).brightness == Brightness.dark ? dark : light;

class DiaryPage extends StatefulWidget {
  final ThemeProvider? themeProvider;
  const DiaryPage({super.key, this.themeProvider});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final DiaryService _service = DiaryService();
  final DiaryCategoryService _catService = DiaryCategoryService();
  List<DiaryEntry> _entries = [];
  List<DiaryCategory> _categories = [];
  String? _selectedCategoryId;
  bool _loaded = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _pinInput = '';
  int _failCount = 0;
  DateTime? _lockoutUntil;
  bool get _isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  // 多选模式状态
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await _service.init(); await _catService.init();
    setState(() { _entries = _service.getAll(); _categories = _catService.getAll(); _loaded = true; });
  }

  void _refresh() { setState(() { _entries = _service.getAll(); _categories = _catService.getAll(); }); }

  List<DiaryEntry> get _filteredEntries {
    var f = _selectedCategoryId == null ? _entries : _entries.where((e) => e.diaryCategory == _selectedCategoryId).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      f = f.where((e) => e.title.toLowerCase().contains(q) || e.content.toLowerCase().contains(q) || e.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    // 置顶优先
    f.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return f;
  }

  // ── 多选 ──
  void _exitSelectMode() { setState(() { _isSelectMode = false; _selectedIds.clear(); }); }
  void _enterSelectMode(String id) { setState(() { _isSelectMode = true; _selectedIds.add(id); }); }
  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) { _selectedIds.remove(id); if (_selectedIds.isEmpty) _isSelectMode = false; }
      else { _selectedIds.add(id); }
    });
  }
  void _toggleSelectAll() {
    setState(() {
      final filtered = _filteredEntries.map((e) => e.id).toList();
      if (_selectedIds.length == filtered.length && _selectedIds.isNotEmpty) { _selectedIds.clear(); _isSelectMode = false; }
      else { _selectedIds.addAll(filtered); }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('批量删除'),
      content: Text('确定要删除选中的 ${_selectedIds.length} 篇日记吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed), child: const Text('删除')),
      ],
    ));
    if (confirm == true) { for (final id in _selectedIds) { await _service.delete(id); } _exitSelectMode(); _refresh(); }
  }

  Future<void> _batchPin() async {
    for (final id in _selectedIds) {
      final entry = _entries.cast<DiaryEntry?>().firstWhere((e) => e?.id == id, orElse: () => null);
      if (entry != null) { entry.pinned = !entry.pinned; await _service.save(entry); }
    }
    _exitSelectMode(); _refresh();
  }

  // ── 长按分类标签菜单 ──
  void _showCategoryChipMenu(String id) {
    final cat = _categories.cast<DiaryCategory?>().firstWhere((c) => c?.id == id, orElse: () => null);
    if (cat == null) return;
    final entryCount = _entries.where((e) => e.diaryCategory == id).length;
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(cat.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ct(context, AppTheme.textBrown, const Color(0xFFF2EAD3))))),
          ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.edit_rounded, color: AppTheme.accentOrange), title: const Text('编辑分类名称', style: TextStyle(fontSize: 15)), onTap: () { Navigator.pop(ctx); _showRenameCategoryDialog(cat); }),
          ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.deleteRed), title: const Text('删除分类', style: TextStyle(fontSize: 15)), onTap: () { Navigator.pop(ctx); _confirmDeleteCategory(cat, entryCount); }),
        ]),
      )),
    );
  }

  void _showRenameCategoryDialog(DiaryCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('编辑分类', style: TextStyle(color: AppTheme.textBrown, fontSize: 18)),
      content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: '输入新名称', filled: true, fillColor: _ct(context, AppTheme.bgColor, const Color(0xFF2E2A26)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
        ElevatedButton(onPressed: () async { final n = ctrl.text.trim(); if (n.isNotEmpty) { Navigator.pop(ctx); cat.name = n; await _catService.save(cat); _refresh(); } }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('确定')),
      ],
    ));
  }

  void _confirmDeleteCategory(DiaryCategory cat, int entryCount) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('删除分类', style: TextStyle(color: AppTheme.textBrown)),
      content: Text(entryCount > 0 ? '「${cat.name}」下有 $entryCount 篇日记，\n删除后日记将归为无分类。' : '确定要删除「${cat.name}」吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
        TextButton(onPressed: () async { Navigator.pop(ctx); for (final e in _entries.where((e) => e.diaryCategory == cat.id)) { e.diaryCategory = null; await _service.save(e); } await _catService.delete(cat.id); if (_selectedCategoryId == cat.id) _selectedCategoryId = null; _refresh(); }, style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed), child: const Text('删除')),
      ],
    ));
  }

  // ── 分类管理弹窗 ──
  void _showCategoryDialog() {
    final nameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.label_outline_rounded, color: AppTheme.accentOrange), SizedBox(width: 8), Text('管理日记分类', style: TextStyle(color: AppTheme.textBrown, fontSize: 18))]),
        content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(hintText: '新分类名称', filled: true, fillColor: AppTheme.bgColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), style: const TextStyle(fontSize: 14)),
          TextButton(onPressed: () async { final n = nameCtrl.text.trim(); if (n.isNotEmpty) { nameCtrl.clear(); final cat = DiaryCategory(id: const Uuid().v4(), name: n); await _catService.save(cat); _refresh(); setDState(() {}); }}, child: const Text('+ 新建', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          ..._categories.map((c) {
            final count = _entries.where((e) => e.diaryCategory == c.id).length;
            return ListTile(dense: true, title: Text(c.name, style: const TextStyle(fontSize: 14)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$count篇', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
              IconButton(icon: Icon(Icons.edit_rounded, size: 16), onPressed: () { _showRenameCategoryDialog(c); setDState(() {}); }),
              IconButton(icon: Icon(Icons.delete_rounded, size: 16, color: count > 0 ? Colors.grey : AppTheme.deleteRed), onPressed: count > 0 ? null : () { _confirmDeleteCategory(c, count); setDState(() {}); }),
            ]));
          }),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭', style: TextStyle(color: AppTheme.textLight)))],
      ),
    ));
  }

  // ── 密码锁屏 ──
  Widget _buildLockScreen(ThemeProvider tp) { /* ... existing lock screen ... */
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('📖 我的日记')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.accentOrange), const SizedBox(height: 16),
        Text(_isLockedOut ? '输错次数过多，请${_lockoutUntil!.difference(DateTime.now()).inSeconds}秒后再试' : '输入密码解锁',
          style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown)), const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(width: 40, height: 40, margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: i < _pinInput.length ? AppTheme.accentOrange : (isDark ? const Color(0xFF2E2A26) : Colors.white), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.accentOrange, width: 2)),
          alignment: Alignment.center, child: i < _pinInput.length ? Text(_pinInput[i], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)) : null))),
        const SizedBox(height: 20),
        SizedBox(width: 280, child: Wrap(alignment: WrapAlignment.center, spacing: 20, runSpacing: 12, children: List.generate(9, (i) => SizedBox(width: 60, height: 50, child: TextButton(onPressed: () => _onPinInput('${i + 1}', tp),
          style: TextButton.styleFrom(backgroundColor: isDark ? const Color(0xFF2E2A26) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('${i + 1}', style: TextStyle(fontSize: 22, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown))))).toList()
          ..add(const SizedBox(width: 60))
          ..add(SizedBox(width: 60, height: 50, child: TextButton(onPressed: () => _onPinInput('0', tp),
            style: TextButton.styleFrom(backgroundColor: isDark ? const Color(0xFF2E2A26) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('0', style: TextStyle(fontSize: 22, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown)))))
          ..add(SizedBox(width: 60, height: 50, child: TextButton(onPressed: () => setState(() { if (_pinInput.isNotEmpty) _pinInput = _pinInput.substring(0, _pinInput.length - 1); }),
            style: TextButton.styleFrom(backgroundColor: isDark ? const Color(0xFF2E2A26) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Icon(Icons.backspace_outlined, color: AppTheme.accentOrange))))),
        ),
      ])),
    );
  }

  void _onPinInput(String digit, ThemeProvider tp) {
    if (_isLockedOut) return;
    if (_pinInput.length >= 4) return;
    setState(() => _pinInput += digit);
    if (_pinInput.length == 4) {
      if (tp.checkPassword(_pinInput)) { _failCount = 0; tp.unlock(); setState(() => _pinInput = ''); }
      else {
        _failCount++;
        if (_failCount >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
          _failCount = 0;
          setState(() => _pinInput = '');
          // 30秒后自动解除锁定
          Future.delayed(const Duration(seconds: 30), () { if (mounted) setState(() => _lockoutUntil = null); });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密码错误，还剩${5 - _failCount}次机会'), backgroundColor: AppTheme.deleteRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating));
          Future.delayed(const Duration(milliseconds: 500), () => setState(() => _pinInput = ''));
        }
      }
    }
  }

  // ── 密码设置弹窗 ──
  void _showPasswordSetupDialog(ThemeProvider? tp) {
    if (tp == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.lock_outline_rounded, size: 28, color: tp.hasPassword ? AppTheme.accentOrange : Colors.grey),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tp.hasPassword ? '密码已开启' : '设置密码保护', style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 4,
            decoration: InputDecoration(labelText: '4位数字密码', hintText: '输入4位数字', filled: true, fillColor: isDark ? const Color(0xFF2E2A26) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            style: TextStyle(fontSize: 24, color: isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown, letterSpacing: 8), textAlign: TextAlign.center),
          if (tp.hasPassword) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(onPressed: () async { Navigator.pop(ctx); await tp.clearPassword(); setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码已关闭'), backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); }, child: const Text('关闭密码', style: TextStyle(color: AppTheme.deleteRed))),
              ElevatedButton(onPressed: () async { final p = ctrl.text.trim(); if (p.length == 4 && int.tryParse(p) != null) { Navigator.pop(ctx); await tp.setPassword(p); setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码已修改'), backgroundColor: AppTheme.doneGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('请输入4位数字'), backgroundColor: AppTheme.deleteRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); } }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('修改密码')),
            ]),
          ] else
            Padding(padding: const EdgeInsets.only(top: 8), child: ElevatedButton(onPressed: () async { final p = ctrl.text.trim(); if (p.length == 4 && int.tryParse(p) != null) { Navigator.pop(ctx); await tp.setPassword(p); setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码已设置'), backgroundColor: AppTheme.doneGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('请输入4位数字'), backgroundColor: AppTheme.deleteRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), behavior: SnackBarBehavior.floating)); } }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('确定', style: TextStyle(color: Colors.white)))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight)))],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    if (tp != null && tp.hasPassword && tp.isLocked) return _buildLockScreen(tp);

    final filtered = _filteredEntries;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown;
    final textSec = isDark ? const Color(0xFFA89F91) : AppTheme.textLight;
    final chipBorder = isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow;

    return Scaffold(
      appBar: _isSelectMode ? _buildSelectAppBar(context, isDark) : AppBar(
        leading: GestureDetector(
          onTap: () => _showPasswordSetupDialog(tp),
          child: Icon(
            tp != null && tp.hasPassword && tp.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: tp != null && tp.hasPassword ? AppTheme.accentOrange : Colors.grey,
            size: 22,
          ),
        ),
        title: const Text('📖 我的日记'),
      ),
      body: !_loaded ? const Center(child: CircularProgressIndicator())
          : PopScope(canPop: !_isSelectMode, onPopInvokedWithResult: (d, _) { if (!d && _isSelectMode) _exitSelectMode(); },
              child: Column(children: [
        // 搜索框（多选时隐藏）
        if (!_isSelectMode)
          Container(height: 38, margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF2E2A26) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: chipBorder)),
            child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(hintText: '搜索日记...', border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: textSec),
                suffixIcon: _searchQuery.isNotEmpty ? GestureDetector(onTap: () { setState(() { _searchQuery = ''; _searchCtrl.clear(); }); }, child: Icon(Icons.close_rounded, size: 16, color: textSec)) : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8)),
              style: TextStyle(fontSize: 14, color: textMain))),
        _buildCategoryBar(context, isDark, chipBorder),
        Expanded(child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_selectedCategoryId == null ? '📝' : '📂', style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16), Text(_selectedCategoryId == null ? '还没有日记哦~\n点击右下角写一篇吧！' : '该分类下还没有日记~', textAlign: TextAlign.center, style: TextStyle(color: textSec, fontSize: 16, height: 1.5)),
              ]))
            : RefreshIndicator(color: AppTheme.accentOrange, onRefresh: _load,
                child: ListView.builder(padding: EdgeInsets.fromLTRB(0, 4, 0, _isSelectMode ? 100 : 80), itemCount: filtered.length, itemBuilder: (_, i) {
                  final entry = filtered[i]; final isSelected = _selectedIds.contains(entry.id);
                  final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(entry.createdAt);
                  const moodEmojis = {'happy': '😊', 'plain': '😐', 'tired': '😴', 'sad': '😢', 'excited': '🤩'};
                  final moodEmoji = entry.mood != null ? moodEmojis[entry.mood] : null;
                  final catName = entry.diaryCategory != null ? _catService.findNameById(entry.diaryCategory) : null;

                  // 多选模式
                  if (_isSelectMode) {
                    return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      elevation: isSelected ? 3 : 1, color: isSelected ? AppTheme.primaryYellow.withValues(alpha: 0.4) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: isSelected ? const BorderSide(color: AppTheme.accentOrange, width: 2) : BorderSide.none),
                      child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => _toggleSelect(entry.id),
                        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(entry.title.isEmpty ? '无标题' : entry.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (entry.content.isNotEmpty) Text(entry.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: textSec)),
                          ])),
                          Container(width: 26, height: 26,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? const Color(0xFF4A90D9) : Colors.transparent,
                              border: Border.all(color: isSelected ? const Color(0xFF4A90D9) : AppTheme.textLight, width: 2)),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
                        ]))),
                    );
                  }

                  // 普通模式
                  return Card(child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryEditorPage(entry: entry))); _refresh(); }, onLongPress: () => _enterSelectMode(entry.id),
                      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          if (entry.pinned) Padding(padding: const EdgeInsets.only(right: 4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: const Text('置顶', style: TextStyle(fontSize: 9, color: AppTheme.accentOrange, fontWeight: FontWeight.w600)))),
                          if (catName != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow, borderRadius: BorderRadius.circular(6)),
                            child: Text(catName, style: TextStyle(fontSize: 9, color: textSec, fontWeight: FontWeight.w500))),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (moodEmoji != null) ...[Text(moodEmoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 4)],
                          Expanded(child: Text(entry.title.isEmpty ? '无标题' : entry.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(dateStr, style: TextStyle(fontSize: 11, color: textSec)),
                        ]),
                        if (entry.images.isNotEmpty) ...[const SizedBox(height: 8), SizedBox(height: 56, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: entry.images.length, separatorBuilder: (_, _) => const SizedBox(width: 4), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(entry.images[i]), width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 56, height: 56, color: AppTheme.bgColor, child: const Icon(Icons.broken_image_rounded, size: 20, color: AppTheme.textLight))))))],
                        if (entry.content.isNotEmpty) ...[const SizedBox(height: 6), Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: textSec, height: 1.3))],
                      ]))),
                  );
                }),
              ),
        ),
      ])),
      bottomNavigationBar: _isSelectMode ? _buildBottomBar(context, isDark) : null,
      floatingActionButton: _isSelectMode ? null : FloatingActionButton(
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryEditorPage())); _refresh(); },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  PreferredSizeWidget _buildSelectAppBar(BuildContext context, bool isDark) {
    final filtered = _filteredEntries;
    return AppBar(backgroundColor: AppTheme.primaryYellow, foregroundColor: AppTheme.textBrown, elevation: 0,
      leadingWidth: 64,
      leading: GestureDetector(onTap: _exitSelectMode, child: const Center(child: Text('取消', style: TextStyle(color: AppTheme.textBrown, fontSize: 16, fontWeight: FontWeight.w500)))),
      title: Text('已选择 ${_selectedIds.length} 项', style: const TextStyle(color: AppTheme.textBrown, fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [TextButton(onPressed: _toggleSelectAll, child: Text(_selectedIds.length == filtered.length ? '取消全选' : '全选', style: const TextStyle(color: AppTheme.accentOrange, fontSize: 16, fontWeight: FontWeight.w600)))],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2E2A26) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))]),
      child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _bottomActionBtn(Icons.push_pin_outlined, '置顶', AppTheme.accentOrange, _batchPin),
        _bottomActionBtn(Icons.delete_outline_rounded, '删除', _selectedIds.isEmpty ? AppTheme.textLight : AppTheme.deleteRed, _selectedIds.isEmpty ? null : _batchDelete),
      ])),
    );
  }

  Widget _bottomActionBtn(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(onTap: onTap ?? () {}, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22), const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _buildCategoryBar(BuildContext context, bool isDark, Color chipBorder) {
    return Container(height: 44, margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: ListView(scrollDirection: Axis.horizontal, children: [
        _categoryChip(null, '全部', isDark, chipBorder),
        ..._categories.map((c) => _categoryChip(c.id, c.name, isDark, chipBorder)),
        Padding(padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(onTap: _showCategoryDialog,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3))),
              alignment: Alignment.center,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 16, color: AppTheme.accentOrange), SizedBox(width: 2),
                Text('分类', style: TextStyle(fontSize: 12, color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
              ]))),
        ),
      ]),
    );
  }

  Widget _categoryChip(String? id, String label, bool isDark, Color chipBorder) {
    final isSelected = _selectedCategoryId == id;
    final canLongPress = id != null;
    return Padding(padding: const EdgeInsets.only(right: 6), child: GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      onLongPress: canLongPress ? () => _showCategoryChipMenu(id) : null,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: isSelected ? AppTheme.accentOrange : (isDark ? const Color(0xFF2E2A26) : Colors.white), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.accentOrange : chipBorder, width: 1.5)),
        alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : (isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown), fontWeight: FontWeight.w600))),
    ));
  }
}