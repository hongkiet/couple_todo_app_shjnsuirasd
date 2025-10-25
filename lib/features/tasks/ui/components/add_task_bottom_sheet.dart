import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/weekly_task_repository.dart';
import '../../logic/weekly_task_bloc.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final TextEditingController inputCtrl;
  final Function(int) onDaySelected;
  final int? selectedDay;

  const AddTaskBottomSheet({
    super.key,
    required this.inputCtrl,
    required this.onDaySelected,
    this.selectedDay,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _noteCtrl = TextEditingController();
  int? _selectedDay;
  bool _isTitleEmpty = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay;
    _isTitleEmpty = widget.inputCtrl.text.trim().isEmpty;

    // Listen to title changes
    widget.inputCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final isEmpty = widget.inputCtrl.text.trim().isEmpty;
    if (_isTitleEmpty != isEmpty) {
      setState(() {
        _isTitleEmpty = isEmpty;
        // Reset selected day when title becomes empty
        if (isEmpty) {
          _selectedDay = null;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.inputCtrl.removeListener(_onTitleChanged);
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thêm task mới',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Task title input
            Text(
              'Tiêu đề task',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.inputCtrl,
              decoration: const InputDecoration(
                hintText: 'Nhập tiêu đề task...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task_alt),
              ),
              autofocus: true,
              onSubmitted: (_) => _addTask(context),
            ),
            const SizedBox(height: 24),

            // Day selector
            Text(
              'Chọn ngày',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _isTitleEmpty ? Theme.of(context).disabledColor : null,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final dayOfWeek = index + 1;
                  final repo = WeeklyTaskRepository();
                  final dayName = repo.getDayName(dayOfWeek);
                  final isSelected = _selectedDay == dayOfWeek;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dayName),
                      selected: isSelected,
                      onSelected: _isTitleEmpty
                          ? null
                          : (selected) {
                              setState(() {
                                _selectedDay = selected ? dayOfWeek : null;
                              });
                              widget.onDaySelected(_selectedDay ?? -1);
                            },
                      disabledColor: Theme.of(
                        context,
                      ).disabledColor.withOpacity(0.1),
                      checkmarkColor: _isTitleEmpty
                          ? Theme.of(context).disabledColor
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Note input
            Text(
              'Ghi chú (tùy chọn)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Thêm ghi chú cho task...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onSubmitted: (_) => _addTask(context),
            ),
            const SizedBox(height: 32),

            // Add button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _selectedDay != null &&
                        widget.inputCtrl.text.trim().isNotEmpty
                    ? () => _addTask(context)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm task'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTask(BuildContext context) {
    final txt = widget.inputCtrl.text.trim();
    if (txt.isEmpty || _selectedDay == null) return;

    final bloc = context.read<WeeklyTaskBloc>();
    final state = bloc.state;
    bloc.add(
      AddWeeklyTask(
        title: txt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        weekStart: state.currentWeekStart,
        dayOfWeek: _selectedDay!,
      ),
    );

    // Clear inputs and close bottom sheet
    widget.inputCtrl.clear();
    _noteCtrl.clear();
    Navigator.of(context).pop();
  }
}
