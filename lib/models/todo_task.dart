class TodoTask {
  final String id;
  String title;
  bool isDone;
  String? category;
  int totalFocusMinutes;
  String? bindTomatoId;
  int priority; // 0=低(灰), 1=中(橙), 2=高(红)
  DateTime? deadline; // 截止日期
  String? repeatType; // null=不重复, 'daily', 'weekly', 'monthly'
  int subTaskTotal;   // 子任务总数
  int subTaskDone;    // 已完成子任务数
  final DateTime createdAt;
  DateTime? completedAt;

  TodoTask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.category,
    this.totalFocusMinutes = 0,
    this.bindTomatoId,
    this.priority = 0,
    this.deadline,
    this.repeatType,
    this.subTaskTotal = 0,
    this.subTaskDone = 0,
    required this.createdAt,
    this.completedAt,
  });

  void toggle() {
    isDone = !isDone;
    completedAt = isDone ? DateTime.now() : null;
  }

  void addFocusMinutes(int minutes) { totalFocusMinutes += minutes; }

  double get progress => subTaskTotal > 0 ? subTaskDone / subTaskTotal : 1.0;

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'isDone': isDone,
        if (category != null) 'category': category,
        'totalFocusMinutes': totalFocusMinutes,
        if (bindTomatoId != null) 'bindTomatoId': bindTomatoId,
        'priority': priority,
        if (deadline != null) 'deadline': deadline!.millisecondsSinceEpoch,
        if (repeatType != null) 'repeatType': repeatType,
        'subTaskTotal': subTaskTotal, 'subTaskDone': subTaskDone,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  factory TodoTask.fromMap(Map<String, dynamic> map) => TodoTask(
        id: map['id'] as String, title: map['title'] as String,
        isDone: map['isDone'] as bool? ?? false,
        category: map['category'] as String?,
        totalFocusMinutes: map['totalFocusMinutes'] as int? ?? 0,
        bindTomatoId: map['bindTomatoId'] as String?,
        priority: map['priority'] as int? ?? 0,
        deadline: map['deadline'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int) : null,
        repeatType: map['repeatType'] as String?,
        subTaskTotal: map['subTaskTotal'] as int? ?? 0,
        subTaskDone: map['subTaskDone'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int) : null,
      );
}