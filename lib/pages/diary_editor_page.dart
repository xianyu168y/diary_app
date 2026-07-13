import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../models/diary_category.dart';
import '../models/diary_entry.dart';
import '../services/diary_category_service.dart';
import '../core/app_dependencies.dart';

/// 心情映射：key → (icon, 标签)
const Map<String, Map<String, dynamic>> _moods = {
  'happy': {'icon': Icons.sentiment_satisfied_rounded, 'label': '开心'},
  'plain': {'icon': Icons.sentiment_neutral_rounded, 'label': '平静'},
  'sad':   {'icon': Icons.sentiment_dissatisfied_rounded, 'label': '忧伤'},
  'excited': {'icon': Icons.lightbulb_rounded, 'label': '灵感'},
  'tired': {'icon': Icons.sentiment_very_dissatisfied_rounded, 'label': '疲惫'},
};

/// 天气选项
const List<Map<String, dynamic>> _weathers = [
  {'icon': Icons.wb_sunny_rounded, 'value': 'sunny'},
  {'icon': Icons.cloud_rounded, 'value': 'cloudy'},
  {'icon': Icons.water_drop_rounded, 'value': 'rainy'},
];

class DiaryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;
  const DiaryEditorPage({super.key, this.entry});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _service = appDependencies.diaryService;
  final DiaryCategoryService _catService = DiaryCategoryService();
  final ImagePicker _picker = ImagePicker();
  String? _selectedMood;
  String? _selectedWeather;
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

  /// 当前日期时间字符串
  String get _formattedDate {
    final now = widget.entry?.createdAt ?? DateTime.now();
    return DateFormat('M月 d, yyyy  HH:mm').format(now);
  }

  @override
  void initState() {
    super.initState();
    _initCategories();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _selectedWeather = widget.entry!.weather;
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
      weather: _selectedWeather,
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

  // ═══════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2E2A26) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1F1C18) : AppTheme.bgColor;
    final textOnSurface = isDark ? const Color(0xFFF2EAD3) : AppTheme.textBrown;
    final textMuted = isDark ? const Color(0xFF8F7F6E) : AppTheme.textLight;
    final accent = isDark ? const Color(0xFFFFAA33) : AppTheme.accentOrange;
    final outline = isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: surfaceColor,
      // ── 自定义顶部栏 ──
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: textOnSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('撰写日记', style: TextStyle(color: textOnSurface, fontSize: 16, fontWeight: FontWeight.w600)),
            Text('WRITE DIARY', style: TextStyle(color: textMuted, fontSize: 10, letterSpacing: 1.5)),
          ],
        ),
        centerTitle: true,
        actions: [
          // 模板按钮
          if (widget.entry == null)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentOrange, size: 22),
              tooltip: '日记模板',
              onPressed: _showTemplateDialog,
            ),
          // 保存按钮
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Material(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _save,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 60),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('保存', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      // ── 主体内容 ──
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // ── 日期 ──
                _DateRow(date: _formattedDate, textMuted: textMuted, accent: accent),
                const SizedBox(height: 12),

                // ── 写作区域 ──
                _WritingCard(
                  titleController: _titleController,
                  contentController: _contentController,
                  cardColor: cardColor,
                  textOnSurface: textOnSurface,
                  outline: outline,
                  surfaceColor: surfaceColor,
                ),
                const SizedBox(height: 16),

                // ── 图片 ──
                if (_images.isNotEmpty) ...[
                  _ImageStrip(
                    images: _images,
                    accent: accent,
                    cardColor: cardColor,
                    surfaceColor: surfaceColor,
                    onTap: _showImagePreview,
                    onDelete: _confirmDeleteImage,
                    onAdd: _pickImages,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── 标签 ──
                _TagSection(
                  tags: _tags,
                  tagController: _tagController,
                  accent: accent,
                  textOnSurface: textOnSurface,
                  textMuted: textMuted,
                  cardColor: cardColor,
                  outline: outline,
                  onAddTag: _addTag,
                  onRemoveTag: (t) => setState(() => _tags.remove(t)),
                ),
                const SizedBox(height: 12),

                // ── 分类 ──
                _CategoryRow(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  selectedCategoryName: _selectedCategoryName,
                  panelOpen: _categoryPanelOpen,
                  accent: accent,
                  textOnSurface: textOnSurface,
                  textMuted: textMuted,
                  cardColor: cardColor,
                  outline: outline,
                  onToggle: () => setState(() => _categoryPanelOpen = !_categoryPanelOpen),
                  onSelect: (id) => setState(() { _selectedCategory = id; _categoryPanelOpen = false; }),
                  onClose: () => setState(() => _categoryPanelOpen = false),
                ),
                const SizedBox(height: 16),

                // ── 心情选择 ──
                _MoodRow(
                  selectedMood: _selectedMood,
                  accent: accent,
                  textOnSurface: textOnSurface,
                  textMuted: textMuted,
                  cardColor: cardColor,
                  outline: outline,
                  onSelect: (key) => setState(() => _selectedMood = _selectedMood == key ? null : key),
                ),
                const SizedBox(height: 12),

                // ── 天气选择 ──
                _WeatherRow(
                  selectedWeather: _selectedWeather,
                  accent: accent,
                  cardColor: cardColor,
                  outline: outline,
                  onSelect: (v) => setState(() => _selectedWeather = _selectedWeather == v ? null : v),
                ),
                const SizedBox(height: 12),

                // ── 添加图片按钮（无图片时显示） ──
                if (_images.isEmpty)
                  _AddImageButton(accent: accent, cardColor: cardColor, outline: outline, onTap: _pickImages),
              ],
            ),
          ),

          // ── 底部工具栏 ──
          _BottomToolbar(
            accent: accent,
            textOnSurface: textOnSurface,
            textMuted: textMuted,
            onPickImages: _pickImages,
            onAddTag: () => _addTag(_tagController.text),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════

/// 日期显示行
class _DateRow extends StatelessWidget {
  final String date;
  final Color textMuted;
  final Color accent;
  const _DateRow({required this.date, required this.textMuted, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 16, color: textMuted),
        const SizedBox(width: 6),
        Text(date, style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// 写作卡片（标题 + 分割线 + 正文）
class _WritingCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final Color cardColor;
  final Color textOnSurface;
  final Color outline;
  final Color surfaceColor;

  const _WritingCard({
    required this.titleController,
    required this.contentController,
    required this.cardColor,
    required this.textOnSurface,
    required this.outline,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                TextField(
                  controller: titleController,
                  decoration: InputDecoration.collapsed(
                    hintText: '标题...',
                    hintStyle: TextStyle(color: outline, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textOnSurface),
                ),
                const SizedBox(height: 12),
                // 分割线
                Container(height: 1, color: outline.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                // 正文
                SizedBox(
                  height: 280,
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration.collapsed(
                      hintText: '记录当下的想法...',
                      hintStyle: TextStyle(color: outline, fontSize: 16),
                    ),
                    style: TextStyle(fontSize: 16, color: textOnSurface, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          // 装饰性渐变圆角
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [outline.withValues(alpha: 0.0), outline.withValues(alpha: 0.15)],
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(80)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片横向滚动条
class _ImageStrip extends StatelessWidget {
  final List<String> images;
  final Color accent;
  final Color cardColor;
  final Color surfaceColor;
  final void Function(int) onTap;
  final void Function(int) onDelete;
  final VoidCallback onAdd;

  const _ImageStrip({
    required this.images,
    required this.accent,
    required this.cardColor,
    required this.surfaceColor,
    required this.onTap,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            if (i == images.length) {
              return GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: accent, size: 24),
                      Text('添加', style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: () => onTap(i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.file(
                      File(images[i]),
                      width: 72, height: 72,
                      fit: BoxFit.cover,
                      cacheWidth: 144, cacheHeight: 144,
                      errorBuilder: (_, _, _) => Container(
                        width: 72, height: 72,
                        color: surfaceColor,
                        child: const Icon(Icons.broken_image_rounded, color: AppTheme.textLight),
                      ),
                    ),
                    Positioned(top: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => onDelete(i),
                        child: Container(
                          padding: const EdgeInsets.all(6),
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
          },
        ),
      ),
    );
  }
}

/// 添加图片按钮（无图片时显示）
class _AddImageButton extends StatelessWidget {
  final Color accent;
  final Color cardColor;
  final Color outline;
  final VoidCallback onTap;

  const _AddImageButton({
    required this.accent,
    required this.cardColor,
    required this.outline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 20, color: accent),
            const SizedBox(width: 6),
            Text('添加图片', style: TextStyle(fontSize: 14, color: accent, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// 标签区域
class _TagSection extends StatelessWidget {
  final List<String> tags;
  final TextEditingController tagController;
  final Color accent;
  final Color textOnSurface;
  final Color textMuted;
  final Color cardColor;
  final Color outline;
  final void Function(String) onAddTag;
  final void Function(String) onRemoveTag;

  const _TagSection({
    required this.tags,
    required this.tagController,
    required this.accent,
    required this.textOnSurface,
    required this.textMuted,
    required this.cardColor,
    required this.outline,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签输入行
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    hintText: '添加标签 #',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 13, color: textOnSurface),
                  onSubmitted: onAddTag,
                ),
              ),
              GestureDetector(
                onTap: () => onAddTag(tagController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_rounded, size: 20, color: accent),
                ),
              ),
            ],
          ),
          // 已有标签
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: tags.map((t) => Chip(
                  label: Text('#$t', style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: accent,
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  onDeleted: () => onRemoveTag(t),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// 分类选择行
class _CategoryRow extends StatelessWidget {
  final List<DiaryCategory> categories;
  final String? selectedCategory;
  final String? selectedCategoryName;
  final bool panelOpen;
  final Color accent;
  final Color textOnSurface;
  final Color textMuted;
  final Color cardColor;
  final Color outline;
  final VoidCallback onToggle;
  final void Function(String) onSelect;
  final VoidCallback onClose;

  const _CategoryRow({
    required this.categories,
    required this.selectedCategory,
    required this.selectedCategoryName,
    required this.panelOpen,
    required this.accent,
    required this.textOnSurface,
    required this.textMuted,
    required this.cardColor,
    required this.outline,
    required this.onToggle,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selectedCategory != null ? accent.withValues(alpha: 0.15) : cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selectedCategory != null ? accent.withValues(alpha: 0.4) : outline),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.label_outline_rounded, size: 14, color: selectedCategory != null ? accent : textMuted),
              const SizedBox(width: 4),
              Text(
                selectedCategoryName ?? '分类',
                style: TextStyle(fontSize: 12, color: selectedCategory != null ? accent : textMuted, fontWeight: FontWeight.w500),
              ),
              Icon(Icons.arrow_drop_down, size: 16, color: selectedCategory != null ? accent : textMuted),
            ]),
          ),
        ),
        if (panelOpen)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ...categories.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => onSelect(c.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedCategory == c.id ? accent : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedCategory == c.id ? accent : AppTheme.primaryYellow),
                      ),
                      child: Text(c.name, style: TextStyle(fontSize: 12, color: selectedCategory == c.id ? Colors.white : AppTheme.textBrown, fontWeight: FontWeight.w500)),
                    ),
                  ),
                )),
                GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.close_rounded, size: 16, color: textMuted),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

/// 心情选择行
class _MoodRow extends StatelessWidget {
  final String? selectedMood;
  final Color accent;
  final Color textOnSurface;
  final Color textMuted;
  final Color cardColor;
  final Color outline;
  final void Function(String) onSelect;

  const _MoodRow({
    required this.selectedMood,
    required this.accent,
    required this.textOnSurface,
    required this.textMuted,
    required this.cardColor,
    required this.outline,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今天的心情', style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moods.entries.map((e) {
                final key = e.key;
                final icon = e.value['icon'] as IconData;
                final label = e.value['label'] as String;
                final isSelected = selectedMood == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelect(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? accent : outline,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 20, color: isSelected ? Colors.white : textMuted),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : textOnSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 天气选择行
class _WeatherRow extends StatelessWidget {
  final String? selectedWeather;
  final Color accent;
  final Color cardColor;
  final Color outline;
  final void Function(String) onSelect;

  const _WeatherRow({
    required this.selectedWeather,
    required this.accent,
    required this.cardColor,
    required this.outline,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _weathers.map((w) {
        final icon = w['icon'] as IconData;
        final value = w['value'] as String;
        final isSelected = selectedWeather == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? accent : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accent : outline,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Icon(icon, size: 22, color: isSelected ? Colors.white : accent.withValues(alpha: 0.8)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 底部工具栏
class _BottomToolbar extends StatelessWidget {
  final Color accent;
  final Color textOnSurface;
  final Color textMuted;
  final VoidCallback onPickImages;
  final VoidCallback onAddTag;

  const _BottomToolbar({
    required this.accent,
    required this.textOnSurface,
    required this.textMuted,
    required this.onPickImages,
    required this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2A26) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF3D3833) : AppTheme.primaryYellow.withValues(alpha: 0.3))),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFADFB0).withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, -4),
        )],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _ToolbarButton(icon: Icons.image_rounded, tooltip: '添加图片', onTap: onPickImages),
                const SizedBox(width: 4),
                const _ToolbarButton(icon: Icons.mic_rounded, tooltip: '录音'),
                const SizedBox(width: 4),
                _ToolbarButton(icon: Icons.label_rounded, tooltip: '添加标签', onTap: onAddTag),
              ],
            ),
            const _ToolbarButton(icon: Icons.more_horiz_rounded, tooltip: '更多'),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF8F7F6E) : AppTheme.textLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: muted),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Full-screen Image Preview
// ═══════════════════════════════════════════════════════════════════

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