import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/diary_category.dart';
import '../models/diary_entry.dart';
import '../services/diary_category_service.dart';
import '../services/diary_service.dart';

/// 心情映射：key → (emoji, 中文名)
const Map<String, Map<String, String>> _moods = {
  'happy': {'emoji': '😊', 'label': '开心'},
  'plain': {'emoji': '😐', 'label': '平淡'},
  'tired': {'emoji': '😴', 'label': '疲惫'},
  'sad':   {'emoji': '😢', 'label': '难过'},
  'excited': {'emoji': '🤩', 'label': '兴奋'},
};

class DiaryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;
  const DiaryEditorPage({super.key, this.entry});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DiaryService _service = DiaryService();
  final DiaryCategoryService _catService = DiaryCategoryService();
  final ImagePicker _picker = ImagePicker();
  String? _selectedMood;
  String? _selectedCategory;
  List<String> _images = [];
  final _tagController = TextEditingController();
  List<String> _tags = [];
  bool _saving = false;
  bool _categoryPanelOpen = false;
  List<DiaryCategory> _categories = [];

  String? get _selectedCategoryName {
    if (_selectedCategory == null) return null;
    final cat = _categories.cast<DiaryCategory?>().firstWhere((c) => c?.id == _selectedCategory, orElse: () => null);
    return cat?.name;
  }

  @override
  void initState() {
    super.initState();
    _initCategories();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _selectedCategory = widget.entry!.diaryCategory;
      _images = List.from(widget.entry!.images);
      _tags = List.from(widget.entry!.tags);
    }
  }

  Future<void> _initCategories() async {
    await _catService.init();
    setState(() => _categories = _catService.getAll());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _service.init();

    final entryId = widget.entry?.id ?? const Uuid().v4();

    final savedImages = <String>[];
    for (int i = 0; i < _images.length; i++) {
      final path = _images[i];
      if (path.contains('diary_images')) {
        savedImages.add(path);
      } else {
        final saved = await _service.saveImage(path, entryId, i);
        savedImages.add(saved);
      }
    }

    final entry = DiaryEntry(
      id: entryId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
      diaryCategory: _selectedCategory,
      tags: _tags,
      images: savedImages,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.save(entry);
    await _service.cleanupOrphanImages(entry);

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  // ── 添加标签 ──
  void _addTag(String t) {
    final tag = t.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() { _tags.add(tag); _tagController.clear(); });
    }
  }

  // ── 日记模板 ──
  void _showTemplateDialog() {
    final templates = {
      '学习复盘': '## 📚 今日学习\n\n### 学了什么\n\n\n### 掌握程度\n\n\n### 待解决\n\n\n### 明日计划\n\n',
      '一日总结': '## 🌟 今日总结\n\n### 开心的事\n\n\n### 挑战\n\n\n### 学到\n\n\n### 感恩\n\n',
      '错题记录': '## ❌ 错题记录\n\n### 科目\n\n\n### 题目\n\n\n### 错误原因\n\n\n### 正确解法\n\n',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('选择模板', style: TextStyle(color: AppTheme.textBrown)),
        content: Column(mainAxisSize: MainAxisSize.min, children: templates.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.description_outlined, color: AppTheme.accentOrange),
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(e.value.split('\n').first, style: const TextStyle(fontSize: 12)),
            onTap: () { Navigator.pop(ctx); _contentController.text = e.value; },
          ),
        )).toList()),
      ),
    );
  }

  // ── 选择图片 ──
  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() => _images.addAll(picked.map((x) => x.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('无法访问相册，请在设置中授予权限'),
          backgroundColor: AppTheme.deleteRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── 删除图片确认 ──
  void _confirmDeleteImage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除图片', style: TextStyle(color: AppTheme.textBrown)),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _images.removeAt(index)); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ── 全屏图片预览 ──
  void _showImagePreview(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImagePreviewPage(
          images: _images,
          initialIndex: initialIndex,
          onDelete: (i) {
            if (i >= 0 && i < _images.length) {
              setState(() => _images.removeAt(i));
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.entry == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2A26) : Colors.white;
    final bgColor = isDark ? const Color(0xFF1F1C18) : AppTheme.bgColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '✏️ 写日记' : '📝 编辑日记'),
        actions: [
          // 模板按钮
          if (isNew)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentOrange),
              tooltip: '日记模板',
              onPressed: () => _showTemplateDialog(),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存', style: TextStyle(color: AppTheme.accentOrange, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 标题
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '今天想记录什么呢？', labelText: '标题'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textBrown),
            ),
            const SizedBox(height: 12),
            // ── 统一图片栏 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: 80,
                child: _images.isEmpty
                    ? Center(
                        child: GestureDetector(
                          onTap: _pickImages,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.accentOrange),
                              const SizedBox(width: 4),
                              Text('添加图片', style: TextStyle(fontSize: 13, color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          if (i == _images.length) return _addImageButton();
                          return _imageThumb(i);
                        },
                      ),
              ),
            ),
            // ── 标签输入 ──
            Row(children: [
              Expanded(child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '添加标签 #', border: InputBorder.none, contentPadding: EdgeInsets.fromLTRB(8, 4, 8, 4), isDense: true),
                style: const TextStyle(fontSize: 13),
                onSubmitted: _addTag,
              )),
              GestureDetector(
                onTap: () => _addTag(_tagController.text),
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_rounded, size: 18, color: AppTheme.accentOrange)),
              ),
            ]),
            // ── 标签 ──
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Wrap(spacing: 4, runSpacing: 2, children: _tags.map((t) => Chip(
                  label: Text('#$t', style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: AppTheme.accentOrange,
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  onDeleted: () => setState(() => _tags.remove(t)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )).toList()),
              ),
            const SizedBox(height: 6),
            // ── 日记分类 ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _categoryPanelOpen = !_categoryPanelOpen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _selectedCategory != null ? (isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow) : bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedCategory != null ? AppTheme.accentOrange.withValues(alpha: 0.4) : (isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.label_outline_rounded, size: 14, color: _selectedCategory != null ? AppTheme.accentOrange : AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCategoryName ?? '分类',
                        style: TextStyle(fontSize: 12, color: _selectedCategory != null ? AppTheme.accentOrange : AppTheme.textLight, fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.arrow_drop_down, size: 16, color: _selectedCategory != null ? AppTheme.accentOrange : AppTheme.textLight),
                    ]),
                  ),
                ),
                if (_categoryPanelOpen)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () => setState(() { _selectedCategory = c.id; _categoryPanelOpen = false; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _selectedCategory == c.id ? AppTheme.accentOrange : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _selectedCategory == c.id ? AppTheme.accentOrange : AppTheme.primaryYellow),
                              ),
                              child: Text(c.name, style: TextStyle(fontSize: 12, color: _selectedCategory == c.id ? Colors.white : AppTheme.textBrown, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        )),
                        GestureDetector(
                          onTap: () => setState(() => _categoryPanelOpen = false),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textLight),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 正文
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: '写点今天的感受吧...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
                style: const TextStyle(fontSize: 16, color: AppTheme.textBrown, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            // ── 心情选择 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今天的心情', style: TextStyle(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.entries.map((e) {
                      final key = e.key;
                      final emoji = e.value['emoji']!;
                      final label = e.value['label']!;
                      final isSelected = _selectedMood == key;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = isSelected ? null : key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? AppTheme.accentOrange : Colors.transparent, width: 1.5),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(label, style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.accentOrange : AppTheme.textLight, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 添加图片按钮 ──
  Widget _addImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.primaryYellow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.accentOrange, size: 24),
            SizedBox(height: 2),
            Text('添加', style: TextStyle(fontSize: 10, color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── 图片缩略图 ──
  Widget _imageThumb(int index) {
    return GestureDetector(
      onTap: () => _showImagePreview(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.file(
              File(_images[index]),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 72, height: 72,
                color: AppTheme.bgColor,
                child: const Icon(Icons.broken_image_rounded, color: AppTheme.textLight),
              ),
            ),
            // 右上角删除按钮
            Positioned(
              top: 2, right: 2,
              child: GestureDetector(
                onTap: () => _confirmDeleteImage(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.deleteRed.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 全屏图片预览页 ──
class _ImagePreviewPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final void Function(int index) onDelete;

  const _ImagePreviewPage({
    required this.images,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteCurrent() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除图片', style: TextStyle(color: AppTheme.textBrown)),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textLight))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final idx = _currentIndex;
              widget.onDelete(idx);
              if (widget.images.length <= 1) {
                Navigator.pop(context);
              } else {
                setState(() {
                  if (_currentIndex >= widget.images.length - 1) {
                    _currentIndex = widget.images.length - 2;
                  }
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.deleteRed),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.deleteRed),
            onPressed: _deleteCurrent,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.images[i]),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}