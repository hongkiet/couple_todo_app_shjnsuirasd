part of 'task_bloc.dart';

enum TaskStatus { loading, ready }

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  const factory TaskEvent.bind() = _BindStream;
  const factory TaskEvent.onTasks(List<Task> tasks) = _OnTasks;

  @override
  List<Object?> get props => [];
}

class _BindStream extends TaskEvent {
  const _BindStream();
}

class _OnTasks extends TaskEvent {
  final List<Task> tasks;
  const _OnTasks(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class AddTask extends TaskEvent {
  final String title;
  const AddTask(this.title);
  @override
  List<Object?> get props => [title];
}

class ToggleTask extends TaskEvent {
  final String id;
  final bool isDone;
  const ToggleTask(this.id, this.isDone);
  @override
  List<Object?> get props => [id, isDone];
}

class DeleteTask extends TaskEvent {
  final String id;
  const DeleteTask(this.id);
  @override
  List<Object?> get props => [id];
}

class RefreshTasks extends TaskEvent {
  const RefreshTasks();
}
