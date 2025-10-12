part of 'weekly_task_bloc.dart';

class WeeklyTaskState extends Equatable {
  final List<WeeklyTask> tasks;
  final WeeklyTasksGroup? tasksGroup;
  final WeeklyTaskStatus status;
  final DateTime currentWeekStart;

  const WeeklyTaskState({
    required this.tasks,
    this.tasksGroup,
    required this.status,
    required this.currentWeekStart,
  });

  WeeklyTaskState.initial()
    : tasks = const [],
      tasksGroup = null,
      status = WeeklyTaskStatus.loading,
      currentWeekStart = _getCurrentWeekStart();

  static DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  WeeklyTaskState copyWith({
    List<WeeklyTask>? tasks,
    WeeklyTasksGroup? tasksGroup,
    WeeklyTaskStatus? status,
    DateTime? currentWeekStart,
  }) {
    return WeeklyTaskState(
      tasks: tasks ?? this.tasks,
      tasksGroup: tasksGroup ?? this.tasksGroup,
      status: status ?? this.status,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
    );
  }

  @override
  List<Object?> get props => [tasks, tasksGroup, status, currentWeekStart];
}
