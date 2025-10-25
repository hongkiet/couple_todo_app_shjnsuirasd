import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/weekly_task_repository.dart';
import '../../logic/weekly_task_bloc.dart';

class WeekNavigation extends StatelessWidget {
  const WeekNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeeklyTaskBloc, WeeklyTaskState>(
      builder: (context, state) {
        final repo = WeeklyTaskRepository();
        final weekRange = repo.formatWeekRange(state.currentWeekStart);
        final bloc = context.read<WeeklyTaskBloc>();

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => bloc.add(const GoToPreviousWeek()),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      weekRange,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${state.tasksGroup?.completedTasks ?? 0}/${state.tasksGroup?.totalTasks ?? 0} hoàn thành',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => bloc.add(const GoToNextWeek()),
              ),
            ],
          ),
        );
      },
    );
  }
}
