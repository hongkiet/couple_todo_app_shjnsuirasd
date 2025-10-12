part of 'task_bloc.dart';

class TaskState extends Equatable {
  final TaskStatus status;
  final List<Task> tasks;
  const TaskState({required this.status, required this.tasks});

  const TaskState.initial() : status = TaskStatus.loading, tasks = const [];

  TaskState copyWith({TaskStatus? status, List<Task>? tasks}) =>
      TaskState(status: status ?? this.status, tasks: tasks ?? this.tasks);

  @override
  List<Object?> get props => [status, tasks];
}
