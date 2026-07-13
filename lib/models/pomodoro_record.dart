class PomodoroRecord {
  final String id;
  final DateTime date;       // 完成日期（兼容旧数据）
  final DateTime startTime;  // 开始时间
  final DateTime endTime;    // 结束时间
  final int minutes;         // 专注时长
  String? categoryId;        // 预留：待办分类绑定

  PomodoroRecord({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.minutes,
    this.categoryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'minutes': minutes,
        if (categoryId != null) 'categoryId': categoryId,
      };

  factory PomodoroRecord.fromMap(Map<String, dynamic> map) {
    final date = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
    return PomodoroRecord(
      id: map['id'] as String,
      date: date,
      startTime: map['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int)
          : date,
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : date,
      minutes: map['minutes'] as int? ?? 25,
      categoryId: map['categoryId'] as String?,
    );
  }
}