import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/weekly_task_repository.dart';
import '../data/weekly_task.dart';
import '../logic/weekly_task_bloc.dart';
import 'components/home_app_bar.dart';
import 'components/week_navigation.dart';
import 'components/add_task_bottom_sheet.dart';
import 'components/weekly_tasks_list.dart';
import 'components/day_tabs.dart';

class HomePage extends StatefulWidget {
  final String coupleId;

  const HomePage({super.key, required this.coupleId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final inputCtrl = TextEditingController();
  int? selectedDayOfWeek;
  bool isExpanded =
      true;

  void _onDaySelected(int? day) {
    setState(() {
      selectedDayOfWeek = day;
      if (day != null) {
        isExpanded =
            false;
      }
    });
  }

  void _toggleExpand() {
    if (selectedDayOfWeek == null) return;

    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        selectedDayOfWeek = null; 
      }
    });
  }

  Map<int, int> _getDayTaskCounts(WeeklyTasksGroup? tasksGroup) {
    if (tasksGroup == null) return {};

    final Map<int, int> counts = {};
    for (int day = 1; day <= 7; day++) {
      counts[day] = tasksGroup.tasksByDay[day]?.length ?? 0;
    }
    return counts;
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        // Lấy bloc từ context của HomePage (parent context)
        final bloc = context.read<WeeklyTaskBloc>();
        return BlocProvider.value(
          value: bloc,
          child: AddTaskBottomSheet(
            inputCtrl: inputCtrl,
            onDaySelected: (day) => setState(() => selectedDayOfWeek = day),
            selectedDay: selectedDayOfWeek,
          ),
        );
      },
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    final completer = Completer<void>();
    final sub = context.read<WeeklyTaskBloc>().stream.listen((state) {
      if (state.status == WeeklyTaskStatus.ready) {
        completer.complete();
      }
    });
    context.read<WeeklyTaskBloc>().add(const RefreshWeeklyTasks());
    await completer.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    await sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WeeklyTaskBloc(
        repo: WeeklyTaskRepository(),
        coupleId: widget.coupleId,
      ),
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: Column(
          children: [
            const WeekNavigation(),
            const Divider(height: 0),
            BlocBuilder<WeeklyTaskBloc, WeeklyTaskState>(
              builder: (context, state) {
                return DayTabs(
                  selectedDay: selectedDayOfWeek,
                  isExpanded: isExpanded,
                  onDaySelected: _onDaySelected,
                  onToggleExpand: _toggleExpand,
                  dayTaskCounts: _getDayTaskCounts(state.tasksGroup),
                );
              },
            ),
            const Divider(height: 0),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: BlocBuilder<WeeklyTaskBloc, WeeklyTaskState>(
                  builder: (context, state) {
                    if (state.status == WeeklyTaskStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
              
                    if (state.tasksGroup == null ||
                        state.tasksGroup!.totalTasks == 0) {
                      return const Center(
                        child: Text('Chưa có task nào trong tuần này.'),
                      );
                    }
              
                    return WeeklyTasksList(
                      tasksGroup: state.tasksGroup!,
                      selectedDay: isExpanded ? null : selectedDayOfWeek,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (fabContext) => FloatingActionButton(
            onPressed: () => _showAddTaskBottomSheet(fabContext),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
