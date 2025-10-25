import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/weekly_task.dart';
import '../../logic/weekly_task_bloc.dart';

class TaskTile extends StatefulWidget {
  final WeeklyTask task;

  const TaskTile({super.key, required this.task});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
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
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.task.title) {
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
      return Card(
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
      );
    }

    return ListTile(
      leading: Checkbox(
        value: widget.task.isDone,
        onChanged: widget.task.id.startsWith('temp_')
            ? null // Disable cho task tạm thời
            : (v) {
                final bloc = context.read<WeeklyTaskBloc>();
                bloc.add(ToggleWeeklyTask(widget.task.id, v ?? false));
              },
      ),
      title: Text(
        widget.task.title,
        style: TextStyle(
          decoration: widget.task.isDone ? TextDecoration.lineThrough : null,
          color: widget.task.isDone ? Colors.grey : null,
          fontWeight: widget.task.isDone ? FontWeight.normal : FontWeight.w500,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _startEditing,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: null, // Disable default onPressed
              tooltip: 'Chỉnh sửa',
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showDeleteDialog(context),
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: null, // Disable default onPressed
              tooltip: 'Xóa',
            ),
          ),
        ],
      ),
      onTap: widget.task.id.startsWith('temp_')
          ? null // Disable tap cho task tạm thời
          : () {
              final bloc = context.read<WeeklyTaskBloc>();
              bloc.add(ToggleWeeklyTask(widget.task.id, !widget.task.isDone));
            },
      onLongPress: _startEditing,
    );
  }
}
