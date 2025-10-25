import 'package:flutter/material.dart';
import '../../data/weekly_task.dart';
import '../../data/weekly_task_repository.dart';
import 'task_tile.dart';

class WeeklyTasksList extends StatelessWidget {
  final WeeklyTasksGroup tasksGroup;
  final int? selectedDay; // null = hiển thị tất cả, 1-7 = chỉ hiển thị ngày đó

  const WeeklyTasksList({
    super.key,
    required this.tasksGroup,
    this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu có ngày được chọn, chỉ hiển thị ngày đó
    if (selectedDay != null) {
      return _buildSingleDayView(context, selectedDay!);
    }

    // Nếu không có ngày được chọn, hiển thị tất cả các ngày
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final dayOfWeek = dayIndex + 1;
        return _buildDayCard(context, dayOfWeek);
      },
    );
  }

  Widget _buildSingleDayView(BuildContext context, int dayOfWeek) {
    final dayTasks = tasksGroup.getTasksForDay(dayOfWeek);
    final repo = WeeklyTaskRepository();
    final dayName = repo.getDayName(dayOfWeek);
    final dayDate = repo.getDayDate(tasksGroup.weekStart, dayOfWeek);

    return Column(
      children: [
        // Header cho ngày được chọn
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$dayName - ${dayDate.day}/${dayDate.month}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dayTasks.where((t) => t.isDone).length}/${dayTasks.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Danh sách tasks của ngày đó
        Expanded(
          child: dayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có task nào cho $dayName',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Theme.of(context).disabledColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dayTasks.length,
                  itemBuilder: (context, index) {
                    return TaskTile(task: dayTasks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, int dayOfWeek) {
    final dayTasks = tasksGroup.getTasksForDay(dayOfWeek);
    final repo = WeeklyTaskRepository();
    final dayName = repo.getDayName(dayOfWeek);
    final dayDate = repo.getDayDate(tasksGroup.weekStart, dayOfWeek);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                '$dayName - ${dayDate.day}/${dayDate.month}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${dayTasks.where((t) => t.isDone).length}/${dayTasks.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: dayTasks.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có task nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : dayTasks.map((task) => TaskTile(task: task)).toList(),
      ),
    );
  }
}
