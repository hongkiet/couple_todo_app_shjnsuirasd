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

      // Khởi tạo với tuần hiện tại
      final currentWeek = _getCurrentWeekStart();
      emit(state.copyWith(currentWeekStart: currentWeek));

      // Load data ngay lập tức cho tuần hiện tại
      add(const RefreshWeeklyTasks());

      // Sử dụng stream để lắng nghe thay đổi từ database
      try {
        _sub = repo
            .watchWeekTasks(coupleId, currentWeek)
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

      // Loại bỏ tất cả task tạm thời khi có data mới từ database
      final realTasks = e.tasks
          .where((task) => !task.id.startsWith('temp_'))
          .toList();

      final group = WeeklyTasksGroup.fromTasks(realTasks);
      emit(
        state.copyWith(
          tasks: realTasks,
          tasksGroup: group,
          status: WeeklyTaskStatus.ready,
        ),
      );
    });

    on<AddWeeklyTask>((e, emit) async {
      // Tạo task tạm thời với optimistic update
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempTask = WeeklyTask(
        id: tempId, // ID tạm thời
        coupleId: coupleId,
        title: e.title,
        note: e.note,
        weekStart: e.weekStart,
        weekEnd: e.weekStart.add(const Duration(days: 6)),
        dayOfWeek: e.dayOfWeek,
        isDone: false,
        createdBy: 'temp', // Sẽ được cập nhật từ API response
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Thêm task tạm thời vào UI ngay lập tức
      final updatedTasks = [...state.tasks, tempTask];
      final updatedGroup = WeeklyTasksGroup.fromTasks(updatedTasks);
      emit(state.copyWith(tasks: updatedTasks, tasksGroup: updatedGroup));

      // Sau đó gọi API để thêm task thật
      try {
        await repo.addTask(
          coupleId: coupleId,
          title: e.title,
          note: e.note,
          weekStart: e.weekStart,
          dayOfWeek: e.dayOfWeek,
        );

        // Sau khi add thành công, refresh data để đảm bảo có task thật
        add(const RefreshWeeklyTasks());
        // print('WeeklyTaskBloc: Task added successfully');
      } catch (error) {
        // Nếu API thất bại, xóa task tạm thời
        // print('Error adding weekly task: $error');
        final rollbackTasks = state.tasks
            .where((task) => task.id != tempId)
            .toList();
        final rollbackGroup = WeeklyTasksGroup.fromTasks(rollbackTasks);
        emit(state.copyWith(tasks: rollbackTasks, tasksGroup: rollbackGroup));
      }
    });

    on<ToggleWeeklyTask>((e, emit) async {
      // Kiểm tra xem task có phải là task tạm thời không
      if (e.id.startsWith('temp_')) {
        // Không cho phép toggle task tạm thời
        return;
      }

      // Optimistic update: cập nhật UI ngay lập tức
      final updatedTasks = state.tasks.map((task) {
        if (task.id == e.id) {
          return task.copyWith(isDone: e.isDone, updatedAt: DateTime.now());
        }
        return task;
      }).toList();

      final updatedGroup = WeeklyTasksGroup.fromTasks(updatedTasks);
      emit(state.copyWith(tasks: updatedTasks, tasksGroup: updatedGroup));

      // Sau đó gọi API để đồng bộ với database
      try {
        await repo.toggleDone(e.id, e.isDone);
        // print('WeeklyTaskBloc: Task toggled successfully');
      } catch (error) {
        // Nếu API thất bại, rollback lại trạng thái cũ
        // print('Error toggling weekly task: $error');
        final rollbackTasks = state.tasks.map((task) {
          if (task.id == e.id) {
            return task.copyWith(isDone: !e.isDone, updatedAt: DateTime.now());
          }
          return task;
        }).toList();

        final rollbackGroup = WeeklyTasksGroup.fromTasks(rollbackTasks);
        emit(state.copyWith(tasks: rollbackTasks, tasksGroup: rollbackGroup));
      }
    });

    on<DeleteWeeklyTask>((e, emit) async {
      // Lưu task để có thể rollback nếu cần
      final taskToDelete = state.tasks.firstWhere((task) => task.id == e.id);

      // Optimistic update: xóa task khỏi UI ngay lập tức
      final updatedTasks = state.tasks
          .where((task) => task.id != e.id)
          .toList();
      final updatedGroup = WeeklyTasksGroup.fromTasks(updatedTasks);
      emit(state.copyWith(tasks: updatedTasks, tasksGroup: updatedGroup));

      // Sau đó gọi API để xóa task thật
      try {
        // print('WeeklyTaskBloc: Deleting weekly task with id: ${e.id}');
        await repo.removeTask(e.id);
        print('WeeklyTaskBloc: Weekly task deleted successfully');
      } catch (error) {
        // Nếu API thất bại, khôi phục lại task
        // print('Error deleting weekly task: $error');
        final rollbackTasks = [...state.tasks, taskToDelete];
        final rollbackGroup = WeeklyTasksGroup.fromTasks(rollbackTasks);
        emit(state.copyWith(tasks: rollbackTasks, tasksGroup: rollbackGroup));
      }
    });

    on<UpdateWeeklyTask>((e, emit) async {
      // Lưu task cũ để có thể rollback nếu cần
      final oldTask = state.tasks.firstWhere((task) => task.id == e.id);

      // Optimistic update: cập nhật UI ngay lập tức
      final updatedTasks = state.tasks.map((task) {
        if (task.id == e.id) {
          return task.copyWith(
            title: e.title ?? task.title,
            note: e.note ?? task.note,
            updatedAt: DateTime.now(),
          );
        }
        return task;
      }).toList();

      final updatedGroup = WeeklyTasksGroup.fromTasks(updatedTasks);
      emit(state.copyWith(tasks: updatedTasks, tasksGroup: updatedGroup));

      // Sau đó gọi API để cập nhật task thật
      try {
        await repo.updateTask(id: e.id, title: e.title, note: e.note);
        // print('WeeklyTaskBloc: Task updated successfully');
      } catch (error) {
        // Nếu API thất bại, rollback lại trạng thái cũ
        // print('Error updating weekly task: $error');
        final rollbackTasks = state.tasks.map((task) {
          if (task.id == e.id) {
            return oldTask;
          }
          return task;
        }).toList();

        final rollbackGroup = WeeklyTasksGroup.fromTasks(rollbackTasks);
        emit(state.copyWith(tasks: rollbackTasks, tasksGroup: rollbackGroup));
      }
    });

    on<RefreshWeeklyTasks>((e, emit) async {
      try {
        // print('WeeklyTaskBloc: Refreshing weekly tasks manually');
        final tasks = await repo.getWeekTasks(coupleId, state.currentWeekStart);
        print('WeeklyTaskBloc: Refreshed ${tasks.length} weekly tasks');

        // Loại bỏ task tạm thời khi refresh
        final realTasks = tasks
            .where((task) => !task.id.startsWith('temp_'))
            .toList();

        final group = WeeklyTasksGroup.fromTasks(realTasks);
        emit(
          state.copyWith(
            tasks: realTasks,
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

        // Load data cho tuần mới ngay lập tức
        final tasks = await repo.getWeekTasks(coupleId, e.weekStart);

        // Loại bỏ task tạm thời khi chuyển tuần
        final realTasks = tasks
            .where((task) => !task.id.startsWith('temp_'))
            .toList();

        final group = WeeklyTasksGroup.fromTasks(realTasks);
        emit(
          state.copyWith(
            currentWeekStart: e.weekStart,
            tasks: realTasks,
            tasksGroup: group,
            status: WeeklyTaskStatus.ready,
          ),
        );

        // Setup stream cho tuần mới
        _sub = repo
            .watchWeekTasks(coupleId, e.weekStart)
            .listen(
              (tasks) => add(WeeklyTaskEvent.onTasks(tasks)),
              onError: (error) {
                // print('WeeklyTaskBloc Stream error: $error');
              },
            );
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

  // Helper method để lấy tuần hiện tại
  DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}
