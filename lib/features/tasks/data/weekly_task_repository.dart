import 'package:supabase_flutter/supabase_flutter.dart';
import 'weekly_task.dart';

class WeeklyTaskRepository {
  final _supa = Supabase.instance.client;

  // Lấy tasks của tuần hiện tại
  Stream<List<WeeklyTask>> watchCurrentWeekTasks(String coupleId) {
    final weekStart = _getCurrentWeekStart();
    // final weekEnd = _getCurrentWeekEnd();
    // Stream theo couple và lọc theo tuần ở client để tương thích SDK
    return _supa
        .from('weekly_tasks')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .order('day_of_week', ascending: true)
        .order('created_at', ascending: true)
        .map((rows) {
          final filtered = rows.where((row) {
            final taskWeekStart = DateTime.parse(row['week_start'] as String);
            return taskWeekStart.year == weekStart.year &&
                taskWeekStart.month == weekStart.month &&
                taskWeekStart.day == weekStart.day;
          }).toList();
          return filtered.map((e) => WeeklyTask.fromMap(e)).toList();
        });
  }

  // Lấy tasks của một tuần cụ thể
  Stream<List<WeeklyTask>> watchWeekTasks(String coupleId, DateTime weekStart) {

    return _supa
        .from('weekly_tasks')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .order('day_of_week', ascending: true)
        .order('created_at', ascending: true)
        .map((rows) {
          final filtered = rows.where((row) {
            final taskWeekStart = DateTime.parse(row['week_start'] as String);
            return taskWeekStart.year == weekStart.year &&
                taskWeekStart.month == weekStart.month &&
                taskWeekStart.day == weekStart.day;
          }).toList();
          return filtered.map((e) => WeeklyTask.fromMap(e)).toList();
        });
  }

  // Thêm task mới
  Future<void> addTask({
    required String coupleId,
    required String title,
    String? note,
    required DateTime weekStart,
    required int dayOfWeek,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 6));

    final insertData = {
      'couple_id': coupleId,
      'title': title,
      'note': note,
      'week_start': weekStart.toIso8601String().split('T')[0],
      'week_end': weekEnd.toIso8601String().split('T')[0],
      'day_of_week': dayOfWeek,
      'created_by': _supa.auth.currentUser!.id,
    };

    print('WeeklyTaskRepository: Adding task with data: $insertData');

    await _supa.from('weekly_tasks').insert(insertData);

    print('WeeklyTaskRepository: Task added successfully');
  }

  // Toggle trạng thái done/undone
  Future<void> toggleDone(String id, bool isDone) async {
    await _supa
        .from('weekly_tasks')
        .update({
          'is_done': isDone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // Xóa task
  Future<void> removeTask(String id) async {
    await _supa.from('weekly_tasks').delete().eq('id', id);
  }

  // Cập nhật task
  Future<void> updateTask({
    required String id,
    String? title,
    String? note,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (note != null) updateData['note'] = note;

    await _supa.from('weekly_tasks').update(updateData).eq('id', id);
  }

  // Lấy tasks của tuần hiện tại (sync)
  Future<List<WeeklyTask>> getCurrentWeekTasks(String coupleId) async {
    final weekStart = _getCurrentWeekStart();
    final weekEnd = _getCurrentWeekEnd();

    print(
      'WeeklyTaskRepository: getCurrentWeekTasks - weekStart: $weekStart, weekEnd: $weekEnd',
    );

    final response = await _supa
        .from('weekly_tasks')
        .select()
        .eq('couple_id', coupleId)
        .eq('week_start', weekStart.toIso8601String().split('T')[0])
        .eq('week_end', weekEnd.toIso8601String().split('T')[0])
        .order('day_of_week', ascending: true)
        .order('created_at', ascending: true);

    print(
      'WeeklyTaskRepository: getCurrentWeekTasks - Raw response: $response',
    );
    final tasks = response.map((e) => WeeklyTask.fromMap(e)).toList();
    print(
      'WeeklyTaskRepository: getCurrentWeekTasks - Parsed ${tasks.length} tasks',
    );
    return tasks;
  }

  // Method để debug - lấy tất cả tasks của couple
  Future<List<WeeklyTask>> getAllTasks(String coupleId) async {
    print(
      'WeeklyTaskRepository: getAllTasks - Getting all tasks for couple: $coupleId',
    );
    final response = await _supa
        .from('weekly_tasks')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: true);

    print('WeeklyTaskRepository: getAllTasks - Raw response: $response');
    final tasks = response.map((e) => WeeklyTask.fromMap(e)).toList();
    print('WeeklyTaskRepository: getAllTasks - Parsed ${tasks.length} tasks');
    return tasks;
  }

  // Lấy tasks của một tuần cụ thể (sync)
  Future<List<WeeklyTask>> getWeekTasks(
    String coupleId,
    DateTime weekStart,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 6));

    final response = await _supa
        .from('weekly_tasks')
        .select()
        .eq('couple_id', coupleId)
        .eq('week_start', weekStart.toIso8601String().split('T')[0])
        .eq('week_end', weekEnd.toIso8601String().split('T')[0])
        .order('day_of_week', ascending: true)
        .order('created_at', ascending: true);

    return response.map((e) => WeeklyTask.fromMap(e)).toList();
  }

  // Helper methods
  DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  DateTime _getCurrentWeekEnd() {
    return _getCurrentWeekStart().add(const Duration(days: 6));
  }

  // Lấy tuần trước
  DateTime getPreviousWeek(DateTime weekStart) {
    return weekStart.subtract(const Duration(days: 7));
  }

  // Lấy tuần sau
  DateTime getNextWeek(DateTime weekStart) {
    return weekStart.add(const Duration(days: 7));
  }

  // Format ngày để hiển thị
  String formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}/${weekStart.month}/${weekStart.year} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
  }

  // Lấy tên ngày trong tuần
  String getDayName(int dayOfWeek) {
    const days = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return days[dayOfWeek];
  }

  // Lấy ngày cụ thể trong tuần
  DateTime getDayDate(DateTime weekStart, int dayOfWeek) {
    return weekStart.add(Duration(days: dayOfWeek - 1));
  }
}
