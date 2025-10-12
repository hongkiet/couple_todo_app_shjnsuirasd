import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../couple/couple_repository.dart';
import '../data/weekly_task.dart';
import '../data/weekly_task_repository.dart';
import '../logic/weekly_task_bloc.dart';

class WeeklyTodoPage extends StatefulWidget {
  const WeeklyTodoPage({super.key});

  @override
  State<WeeklyTodoPage> createState() => _WeeklyTodoPageState();
}

class _WeeklyTodoPageState extends State<WeeklyTodoPage> {
  String? coupleId;
  final inputCtrl = TextEditingController();
  int? selectedDayOfWeek;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await CoupleRepository().myCoupleId();
    setState(() => coupleId = id);
  }

  Future<void> _debugTasks(BuildContext context) async {
    if (coupleId == null) return;

    final repo = WeeklyTaskRepository();

    // Test lấy tất cả tasks
    final allTasks = await repo.getAllTasks(coupleId!);
    print('DEBUG: All tasks: ${allTasks.length}');
    for (final task in allTasks) {
      print(
        'DEBUG: Task - ${task.title}, Week: ${task.weekStart}, Day: ${task.dayOfWeek}',
      );
    }

    // Test lấy tasks tuần hiện tại
    final currentWeekTasks = await repo.getCurrentWeekTasks(coupleId!);
    print('DEBUG: Current week tasks: ${currentWeekTasks.length}');

    // Show dialog với thông tin debug
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Couple ID: $coupleId'),
              Text('All tasks: ${allTasks.length}'),
              Text('Current week tasks: ${currentWeekTasks.length}'),
              if (allTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Sample task:'),
                Text('Title: ${allTasks.first.title}'),
                Text('Week: ${allTasks.first.weekStart}'),
                Text('Day: ${allTasks.first.dayOfWeek}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (coupleId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) =>
          WeeklyTaskBloc(repo: WeeklyTaskRepository(), coupleId: coupleId!),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo Tuần'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<WeeklyTaskBloc>().add(
                const RefreshWeeklyTasks(),
              ),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => _debugTasks(context),
              tooltip: 'Debug',
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => context.go('/home'),
              tooltip: 'Todo Thường',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) context.go('/');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _WeekNavigation(),
            const Divider(height: 0),
            _AddTaskSection(
              inputCtrl: inputCtrl,
              onDaySelected: (day) => setState(() => selectedDayOfWeek = day),
              selectedDay: selectedDayOfWeek,
            ),
            const Divider(height: 0),
            Expanded(
              child: BlocListener<WeeklyTaskBloc, WeeklyTaskState>(
                listener: (context, state) {
                  print(
                    'WeeklyTodoPage: State changed - ${state.tasks.length} tasks, status: ${state.status}',
                  );
                },
                child: BlocBuilder<WeeklyTaskBloc, WeeklyTaskState>(
                  builder: (context, state) {
                    print(
                      'WeeklyTodoPage: Building UI with ${state.tasks.length} tasks',
                    );

                    if (state.status == WeeklyTaskStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.tasksGroup == null ||
                        state.tasksGroup!.totalTasks == 0) {
                      return const Center(
                        child: Text('Chưa có task nào trong tuần này.'),
                      );
                    }

                    return _WeeklyTasksList(tasksGroup: state.tasksGroup!);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeeklyTaskBloc, WeeklyTaskState>(
      builder: (context, state) {
        final repo = WeeklyTaskRepository();
        final weekRange = repo.formatWeekRange(state.currentWeekStart);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.read<WeeklyTaskBloc>().add(
                  const GoToPreviousWeek(),
                ),
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
                onPressed: () =>
                    context.read<WeeklyTaskBloc>().add(const GoToNextWeek()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddTaskSection extends StatefulWidget {
  final TextEditingController inputCtrl;
  final Function(int) onDaySelected;
  final int? selectedDay;

  const _AddTaskSection({
    required this.inputCtrl,
    required this.onDaySelected,
    this.selectedDay,
  });

  @override
  State<_AddTaskSection> createState() => _AddTaskSectionState();
}

class _AddTaskSectionState extends State<_AddTaskSection> {
  bool _showAdvanced = false;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final dayOfWeek = index + 1;
                final repo = WeeklyTaskRepository();
                final dayName = repo.getDayName(dayOfWeek);
                final isSelected = widget.selectedDay == dayOfWeek;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(dayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        widget.onDaySelected(dayOfWeek);
                      } else {
                        widget.onDaySelected(-1);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.inputCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Thêm task...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTask(context),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showAdvanced
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                tooltip: 'Thêm ghi chú',
              ),
              FilledButton(
                onPressed: widget.selectedDay != null
                    ? () => _addTask(context)
                    : null,
                child: const Text('Thêm'),
              ),
            ],
          ),
          // Advanced options
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Ghi chú (tùy chọn)...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
              onSubmitted: (_) => _addTask(context),
            ),
          ],
        ],
      ),
    );
  }

  void _addTask(BuildContext context) {
    final txt = widget.inputCtrl.text.trim();
    if (txt.isEmpty || widget.selectedDay == null) return;

    final state = context.read<WeeklyTaskBloc>().state;
    context.read<WeeklyTaskBloc>().add(
      AddWeeklyTask(
        title: txt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        weekStart: state.currentWeekStart,
        dayOfWeek: widget.selectedDay!,
      ),
    );
    widget.inputCtrl.clear();
    _noteCtrl.clear();
    setState(() => _showAdvanced = false);
  }
}

class _WeeklyTasksList extends StatelessWidget {
  final WeeklyTasksGroup tasksGroup;

  const _WeeklyTasksList({required this.tasksGroup});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final dayOfWeek = dayIndex + 1;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                : dayTasks.map((task) => _TaskTile(task: task)).toList(),
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatefulWidget {
  final WeeklyTask task;

  const _TaskTile({required this.task});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _noteController = TextEditingController(text: widget.task.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.task.title) {
      HapticFeedback.mediumImpact();
      // Lưu reference đến bloc trước khi sử dụng
      final bloc = context.read<WeeklyTaskBloc>();
      bloc.add(
        UpdateWeeklyTask(
          id: widget.task.id,
          title: newTitle,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = false;
      _titleController.text = widget.task.title;
      _noteController.text = widget.task.note ?? '';
    });
  }

  void _showDeleteDialog(BuildContext context) {
    final bloc = context.read<WeeklyTaskBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa task'),
        content: Text('Bạn có chắc muốn xóa task "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              bloc.add(DeleteWeeklyTask(widget.task.id));
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.close),
                      label: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveEdit,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ListTile(
        leading: Checkbox(
          value: widget.task.isDone,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            final bloc = context.read<WeeklyTaskBloc>();
            bloc.add(ToggleWeeklyTask(widget.task.id, v ?? false));
          },
        ),
        title: Text(
          widget.task.title,
          style: TextStyle(
            decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
            color: widget.task.isDone ? Colors.grey : null,
            fontWeight: widget.task.isDone
                ? FontWeight.normal
                : FontWeight.w500,
          ),
        ),
        subtitle: widget.task.note != null && widget.task.note!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.task.note!,
                  style: TextStyle(
                    color: widget.task.isDone ? Colors.grey : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _startEditing,
              tooltip: 'Chỉnh sửa',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(context),
              tooltip: 'Xóa',
            ),
          ],
        ),
        onLongPress: _startEditing,
        onTap: () {
          // Toggle checkbox khi tap vào task
          HapticFeedback.lightImpact();
          final bloc = context.read<WeeklyTaskBloc>();
          bloc.add(ToggleWeeklyTask(widget.task.id, !widget.task.isDone));
        },
      ),
    );
  }
}
