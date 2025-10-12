part of 'weekly_task_bloc.dart';

enum WeeklyTaskStatus { loading, ready }

abstract class WeeklyTaskEvent extends Equatable {
  const WeeklyTaskEvent();
  factory WeeklyTaskEvent.bind() = _BindStream;
  factory WeeklyTaskEvent.onTasks(List<WeeklyTask> tasks) = _OnTasks;

  @override
  List<Object?> get props => [];
}

class _BindStream extends WeeklyTaskEvent {
  const _BindStream();
}

class _OnTasks extends WeeklyTaskEvent {
  final List<WeeklyTask> tasks;
  const _OnTasks(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class AddWeeklyTask extends WeeklyTaskEvent {
  final String title;
  final String? note;
  final DateTime weekStart;
  final int dayOfWeek;

  const AddWeeklyTask({
    required this.title,
    this.note,
    required this.weekStart,
    required this.dayOfWeek,
  });

  @override
  List<Object?> get props => [title, note, weekStart, dayOfWeek];
}

class ToggleWeeklyTask extends WeeklyTaskEvent {
  final String id;
  final bool isDone;

  const ToggleWeeklyTask(this.id, this.isDone);

  @override
  List<Object?> get props => [id, isDone];
}

class DeleteWeeklyTask extends WeeklyTaskEvent {
  final String id;

  const DeleteWeeklyTask(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateWeeklyTask extends WeeklyTaskEvent {
  final String id;
  final String? title;
  final String? note;

  const UpdateWeeklyTask({required this.id, this.title, this.note});

  @override
  List<Object?> get props => [id, title, note];
}

class RefreshWeeklyTasks extends WeeklyTaskEvent {
  const RefreshWeeklyTasks();
}

class ChangeWeek extends WeeklyTaskEvent {
  final DateTime weekStart;

  const ChangeWeek(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}

class GoToPreviousWeek extends WeeklyTaskEvent {
  const GoToPreviousWeek();
}

class GoToNextWeek extends WeeklyTaskEvent {
  const GoToNextWeek();
}

class GoToCurrentWeek extends WeeklyTaskEvent {
  const GoToCurrentWeek();
}
