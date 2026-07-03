class DiaryEntry {
  final String id;
  String title;
  String content;
  String? mood;
  String? diaryCategory;
  List<String> tags;
  List<String> images;
  bool pinned;
  final DateTime createdAt;
  DateTime updatedAt;

  DiaryEntry({
    required this.id,
    this.title = '',
    this.content = '',
    this.mood,
    this.diaryCategory,
    this.tags = const [],
    this.images = const [],
    this.pinned = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'content': content,
        if (mood != null) 'mood': mood,
        if (diaryCategory != null) 'diaryCategory': diaryCategory,
        if (tags.isNotEmpty) 'tags': tags,
        if (images.isNotEmpty) 'images': images,
        if (pinned) 'pinned': true,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory DiaryEntry.fromMap(Map<String, dynamic> map) => DiaryEntry(
        id: map['id'] as String, title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        mood: map['mood'] as String?,
        diaryCategory: map['diaryCategory'] as String?,
        tags: (map['tags'] as List?)?.cast<String>() ?? [],
        images: (map['images'] as List?)?.cast<String>() ?? [],
        pinned: map['pinned'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
}