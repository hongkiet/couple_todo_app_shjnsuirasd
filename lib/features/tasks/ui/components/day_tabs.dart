import 'package:flutter/material.dart';

class DayTabs extends StatelessWidget {
  final int? selectedDay;
  final bool isExpanded;
  final Function(int?) onDaySelected;
  final VoidCallback onToggleExpand;
  final Map<int, int> dayTaskCounts; // Số lượng task cho mỗi ngày

  const DayTabs({
    super.key,
    required this.selectedDay,
    required this.isExpanded,
    required this.onDaySelected,
    required this.onToggleExpand,
    required this.dayTaskCounts,
  });

  static const List<String> dayNames = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];

  static const List<String> dayShortNames = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Icon expand/collapse
          GestureDetector(
            onTap: selectedDay != null ? onToggleExpand : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selectedDay != null
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: selectedDay != null
                    ? null
                    : Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Icon(
                isExpanded ? Icons.view_agenda : Icons.calendar_today,
                color: selectedDay != null
                    ? Theme.of(context).primaryColor
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Day tabs với scroll horizontal
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final dayIndex = index + 1; // 1-7 (Thứ 2-Chủ nhật)
                  final isSelected = selectedDay == dayIndex;
                  final taskCount = dayTaskCounts[dayIndex] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onDaySelected(dayIndex),
                      child: Container(
                        height: 48, // Chiều cao cố định cho tab
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayShortNames[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            if (taskCount > 0) ...[
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$taskCount',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
