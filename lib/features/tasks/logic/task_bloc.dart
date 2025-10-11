import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/task.dart';
import '../data/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repo;
  StreamSubscription<List<Task>>? _sub;
  final String coupleId;

  TaskBloc({required this.repo, required this.coupleId})
    : super(const TaskState.initial()) {
    on<_BindStream>((e, emit) async {
      await _sub?.cancel();
      _sub = repo
          .watchTasks(coupleId)
          .listen((tasks) => add(TaskEvent.onTasks(tasks)));
    });
    on<_OnTasks>(
      (e, emit) =>
          emit(state.copyWith(tasks: e.tasks, status: TaskStatus.ready)),
    );
    on<AddTask>((e, emit) => repo.add(coupleId, e.title));
    on<ToggleTask>((e, emit) => repo.toggleDone(e.id, e.isDone));
    on<DeleteTask>((e, emit) => repo.remove(e.id));

    add(TaskEvent.bind());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
