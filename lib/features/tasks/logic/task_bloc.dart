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
          .listen(
            (tasks) => add(TaskEvent.onTasks(tasks)),
            onError: (error) {
              print('Stream error: $error');
              // Emit error state if needed
            },
          );
    });
    on<_OnTasks>((e, emit) {
      print('TaskBloc: Received ${e.tasks.length} tasks from stream');
      emit(state.copyWith(tasks: e.tasks, status: TaskStatus.ready));
    });
    on<AddTask>((e, emit) async {
      try {
        await repo.add(coupleId, e.title);
      } catch (error) {
        // Handle error if needed
        print('Error adding task: $error');
      }
    });
    on<ToggleTask>((e, emit) async {
      try {
        await repo.toggleDone(e.id, e.isDone);
      } catch (error) {
        // Handle error if needed
        print('Error toggling task: $error');
      }
    });
    on<DeleteTask>((e, emit) async {
      try {
        print('TaskBloc: Deleting task with id: ${e.id}');
        await repo.remove(e.id);
        print('TaskBloc: Task deleted successfully');

        // Manually refresh tasks to ensure UI updates
        add(const RefreshTasks());
      } catch (error) {
        print('Error deleting task: $error');
        // Could emit error state here if needed
      }
    });
    on<RefreshTasks>((e, emit) async {
      try {
        print('TaskBloc: Refreshing tasks manually');
        final tasks = await repo.getTasks(coupleId);
        print('TaskBloc: Refreshed ${tasks.length} tasks');
        emit(state.copyWith(tasks: tasks, status: TaskStatus.ready));
      } catch (error) {
        print('Error refreshing tasks: $error');
      }
    });

    add(TaskEvent.bind());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
