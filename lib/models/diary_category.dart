class DiaryCategory {
  final String id;
  String name;

  DiaryCategory({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory DiaryCategory.fromMap(Map<String, dynamic> map) => DiaryCategory(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
      );
}