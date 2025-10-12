import 'package:supabase_flutter/supabase_flutter.dart';
import 'task.dart';

class TaskRepository {
  final _supa = Supabase.instance.client;

  Stream<List<Task>> watchTasks(String coupleId) {
    return _supa
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((e) => Task.fromMap(e)).toList());
  }

  Future<void> add(String coupleId, String title) async {
    await _supa.from('tasks').insert({
      'couple_id': coupleId,
      'title': title,
      'created_by': _supa.auth.currentUser!.id,
    });
  }

  Future<void> toggleDone(String id, bool isDone) async {
    await _supa
        .from('tasks')
        .update({
          'is_done': isDone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> remove(String id) async {
    print('TaskRepository: Attempting to delete task with id: $id');
    final result = await _supa.from('tasks').delete().eq('id', id);
    print('TaskRepository: Delete result: $result');
  }

  Future<List<Task>> getTasks(String coupleId) async {
    final response = await _supa
        .from('tasks')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: true);

    return response.map((e) => Task.fromMap(e)).toList();
  }
}
