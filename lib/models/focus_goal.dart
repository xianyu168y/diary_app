class FocusGoal {
  final String id;
  String name;       // 目标名称
  DateTime deadline; // 截止日期
  int targetHours;   // 目标总时长（小时）
  bool completed;    // 是否提前完成

  FocusGoal({
    required this.id,
    required this.name,
    required this.deadline,
    required this.targetHours,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'deadline': deadline.millisecondsSinceEpoch,
        'targetHours': targetHours,
        if (completed) 'completed': true,
      };

  factory FocusGoal.fromMap(Map<String, dynamic> map) => FocusGoal(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
        targetHours: map['targetHours'] as int? ?? 0,
        completed: map['completed'] as bool? ?? false,
      );
}