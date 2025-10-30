import 'package:equatable/equatable.dart';

class WeeklyTask extends Equatable {
  final String id;
  final String coupleId;
  final String title;
  final String? note;
  final DateTime weekStart; // Ngày đầu tuần (Thứ 2)
  final DateTime weekEnd; // Ngày cuối tuần (Chủ nhật)
  final int dayOfWeek; // 1-7 (Thứ 2 = 1, Chủ nhật = 7)
  final bool isDone;
  final String createdBy; // User ID của người tạo
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeeklyTask({
    required this.id,
    required this.coupleId,
    required this.title,
    this.note,
    required this.weekStart,
    required this.weekEnd,
    required this.dayOfWeek,
    required this.isDone,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WeeklyTask.fromMap(Map<String, dynamic> m) => WeeklyTask(
    id: m['id'] as String,
    coupleId: m['couple_id'] as String,
    title: m['title'] as String,
    note: m['note'] as String?,
    weekStart: DateTime.parse(m['week_start'] as String),
    weekEnd: DateTime.parse(m['week_end'] as String),
    dayOfWeek: m['day_of_week'] as int,
    isDone: (m['is_done'] as bool?) ?? false,
    createdBy: m['created_by'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'couple_id': coupleId,
    'title': title,
    'note': note,
    'week_start': weekStart.toIso8601String(),
    'week_end': weekEnd.toIso8601String(),
    'day_of_week': dayOfWeek,
    'is_done': isDone,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    coupleId,
    title,
    note,
    weekStart,
    weekEnd,
    dayOfWeek,
    isDone,
    createdBy,
    createdAt,
    updatedAt,
  ];

  WeeklyTask copyWith({
    String? title,
    String? note,
    bool? isDone,
    DateTime? updatedAt,
  }) => WeeklyTask(
    id: id,
    coupleId: coupleId,
    title: title ?? this.title,
    note: note ?? this.note,
    weekStart: weekStart,
    weekEnd: weekEnd,
    dayOfWeek: dayOfWeek,
    isDone: isDone ?? this.isDone,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  // Helper methods
  String get dayName {
    const days = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return days[dayOfWeek];
  }

  DateTime get dayDate {
    return weekStart.add(Duration(days: dayOfWeek - 1));
  }

  String get dayDateFormatted {
    return '${dayDate.day}/${dayDate.month}/${dayDate.year}';
  }

  String get weekRange {
    return '${weekStart.day}/${weekStart.month}/${weekStart.year} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
  }
}

// Helper class để group tasks theo ngày trong tuần
class WeeklyTasksGroup {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<int, List<WeeklyTask>> tasksByDay; // dayOfWeek -> List<WeeklyTask>

  WeeklyTasksGroup({
    required this.weekStart,
    required this.weekEnd,
    required this.tasksByDay,
  });

  factory WeeklyTasksGroup.fromTasks(
    List<WeeklyTask> tasks, {
    DateTime? weekStart,
  }) {
    if (tasks.isEmpty) {
      final ws = weekStart ?? _getWeekStart(DateTime.now());
      final weekEnd = ws.add(const Duration(days: 6));
      return WeeklyTasksGroup(
        weekStart: ws,
        weekEnd: weekEnd,
        tasksByDay: {},
      );
    }

    final firstTask = tasks.first;
    final ws = weekStart ?? firstTask.weekStart;
    final weekEnd = firstTask.weekEnd;

    final tasksByDay = <int, List<WeeklyTask>>{};
    for (int day = 1; day <= 7; day++) {
      tasksByDay[day] = tasks.where((t) => t.dayOfWeek == day).toList();
    }

    return WeeklyTasksGroup(
      weekStart: ws,
      weekEnd: weekEnd,
      tasksByDay: tasksByDay,
    );
  }

  static DateTime _getWeekStart(DateTime date) {
    // Tính ngày Thứ 2 của tuần
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  List<WeeklyTask> getTasksForDay(int dayOfWeek) {
    return tasksByDay[dayOfWeek] ?? [];
  }

  int get totalTasks =>
      tasksByDay.values.fold(0, (sum, tasks) => sum + tasks.length);
  int get completedTasks => tasksByDay.values.fold(
    0,
    (sum, tasks) => sum + tasks.where((t) => t.isDone).length,
  );
}
