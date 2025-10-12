import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../couple/couple_repository.dart';
import '../data/task_repository.dart';
import '../logic/task_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final inputCtrl = TextEditingController();
  String? coupleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await CoupleRepository().myCoupleId();
    setState(() => coupleId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (coupleId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) => TaskBloc(repo: TaskRepository(), coupleId: coupleId!),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shared Tasks'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_view_week),
              onPressed: () => context.go('/weekly'),
              tooltip: 'Todo Tuần',
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
            _TaskInputField(inputCtrl: inputCtrl),
            const Divider(height: 0),
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state.status == TaskStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.tasks.isEmpty) {
                    return const Center(child: Text('No tasks yet.'));
                  }
                  return ListView.separated(
                    itemCount: state.tasks.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final t = state.tasks[i];
                      return ListTile(
                        leading: Checkbox(
                          value: t.isDone,
                          onChanged: (v) => context.read<TaskBloc>().add(
                            ToggleTask(t.id, v ?? false),
                          ),
                        ),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            decoration: t.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              context.read<TaskBloc>().add(DeleteTask(t.id)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskInputField extends StatelessWidget {
  final TextEditingController inputCtrl;

  const _TaskInputField({required this.inputCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: inputCtrl,
              decoration: const InputDecoration(hintText: 'Add a task...'),
              onSubmitted: (_) => _add(context),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _add(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _add(BuildContext context) {
    final txt = inputCtrl.text.trim();
    if (txt.isEmpty) return;
    context.read<TaskBloc>().add(AddTask(txt));
    inputCtrl.clear();
  }
}
