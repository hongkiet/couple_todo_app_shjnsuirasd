import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/weekly_task.dart';
import '../data/weekly_task_repository.dart';

part 'weekly_task_event.dart';
part 'weekly_task_state.dart';

class WeeklyTaskBloc extends Bloc<WeeklyTaskEvent, WeeklyTaskState> {
  final WeeklyTaskRepository repo;
  StreamSubscription<List<WeeklyTask>>? _sub;
  Timer? _refreshTimer;
  final String coupleId;

  WeeklyTaskBloc({required this.repo, required this.coupleId})
    : super(WeeklyTaskState.initial()) {
    on<_BindStream>((e, emit) async {
      await _sub?.cancel();
      _refreshTimer?.cancel();
      // print('WeeklyTaskBloc: Binding stream for coupleId: $coupleId');

      // Load data ngay lập tức
      add(const RefreshWeeklyTasks());

      // Setup timer để refresh định kỳ mỗi 5 giây
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // print('WeeklyTaskBloc: Periodic refresh...');
        add(const RefreshWeeklyTasks());
      });

      // Thử cách 1: Sử dụng stream
      try {
        _sub = repo
            .watchCurrentWeekTasks(coupleId)
            .listen(
              (tasks) {
                // print('WeeklyTaskBloc: Stream received ${tasks.length} tasks');
                add(WeeklyTaskEvent.onTasks(tasks));
              },
              onError: (error) {
                // print('WeeklyTaskBloc Stream error: $error');
                // Fallback: load data manually
                add(const RefreshWeeklyTasks());
              },
            );
      } catch (error) {
        // print(
        //   'WeeklyTaskBloc: Stream failed, falling back to manual load: $error',
        // );
        // Fallback: load data manually
        add(const RefreshWeeklyTasks());
      }
    });

    on<_OnTasks>((e, emit) {
      // print(
      //   'WeeklyTaskBloc: Received ${e.tasks.length} weekly tasks from stream',
      // );
      final group = WeeklyTasksGroup.fromTasks(e.tasks);
      emit(
        state.copyWith(
          tasks: e.tasks,
          tasksGroup: group,
          status: WeeklyTaskStatus.ready,
        ),
      );
    });

    on<AddWeeklyTask>((e, emit) async {
      try {
        await repo.addTask(
          coupleId: coupleId,
          title: e.title,
          note: e.note,
          weekStart: e.weekStart,
          dayOfWeek: e.dayOfWeek,
        );

        // Force refresh sau khi thêm task
        // print('WeeklyTaskBloc: Task added, refreshing...');
        add(const RefreshWeeklyTasks());
      } catch (error) {
        // print('Error adding weekly task: $error');
      }
    });

    on<ToggleWeeklyTask>((e, emit) async {
      try {
        await repo.toggleDone(e.id, e.isDone);
        // Force refresh sau khi toggle
        add(const RefreshWeeklyTasks());
      } catch (error) {
        // print('Error toggling weekly task: $error');
      }
    });

    on<DeleteWeeklyTask>((e, emit) async {
      try {
        // print('WeeklyTaskBloc: Deleting weekly task with id: ${e.id}');
        await repo.removeTask(e.id);
        print('WeeklyTaskBloc: Weekly task deleted successfully');

        // Manually refresh tasks to ensure UI updates
        add(const RefreshWeeklyTasks());
      } catch (error) {
        // print('Error deleting weekly task: $error');
      }
    });

    on<UpdateWeeklyTask>((e, emit) async {
      try {
        await repo.updateTask(id: e.id, title: e.title, note: e.note);
      } catch (error) {
        // print('Error updating weekly task: $error');
      }
    });

    on<RefreshWeeklyTasks>((e, emit) async {
      try {
        // print('WeeklyTaskBloc: Refreshing weekly tasks manually');
        final tasks = await repo.getCurrentWeekTasks(coupleId);
        print('WeeklyTaskBloc: Refreshed ${tasks.length} weekly tasks');
        final group = WeeklyTasksGroup.fromTasks(tasks);
        emit(
          state.copyWith(
            tasks: tasks,
            tasksGroup: group,
            status: WeeklyTaskStatus.ready,
          ),
        );
      } catch (error) {
        // print('Error refreshing weekly tasks: $error');
      }
    });

    on<ChangeWeek>((e, emit) async {
      try {
        // print('WeeklyTaskBloc: Changing to week ${e.weekStart}');
        await _sub?.cancel();

        _sub = repo
            .watchWeekTasks(coupleId, e.weekStart)
            .listen(
              (tasks) => add(WeeklyTaskEvent.onTasks(tasks)),
              onError: (error) {
                // print('WeeklyTaskBloc Stream error: $error');
              },
            );

        emit(state.copyWith(currentWeekStart: e.weekStart));
      } catch (error) {
        // print('Error changing week: $error');
      }
    });

    on<GoToPreviousWeek>((e, emit) async {
      final previousWeek = repo.getPreviousWeek(state.currentWeekStart);
      add(ChangeWeek(previousWeek));
    });

    on<GoToNextWeek>((e, emit) async {
      final nextWeek = repo.getNextWeek(state.currentWeekStart);
      add(ChangeWeek(nextWeek));
    });

    on<GoToCurrentWeek>((e, emit) async {
      final now = DateTime.now();
      final weekday = now.weekday;
      final currentWeek = now.subtract(Duration(days: weekday - 1));
      add(ChangeWeek(currentWeek));
    });

    add(WeeklyTaskEvent.bind());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}
