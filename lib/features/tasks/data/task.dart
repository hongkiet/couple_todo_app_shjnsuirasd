import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String coupleId;
  final String title;
  final String? note;
  final DateTime? dueAt;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.coupleId,
    required this.title,
    this.note,
    this.dueAt,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> m) => Task(
    id: m['id'] as String,
    coupleId: m['couple_id'] as String,
    title: m['title'] as String,
    note: m['note'] as String?,
    dueAt: m['due_at'] == null ? null : DateTime.parse(m['due_at'] as String),
    isDone: (m['is_done'] as bool?) ?? false,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'couple_id': coupleId,
    'title': title,
    'note': note,
    'due_at': dueAt?.toIso8601String(),
    'is_done': isDone,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    coupleId,
    title,
    note,
    dueAt,
    isDone,
    createdAt,
    updatedAt,
  ];

  Task copyWith({
    String? title,
    String? note,
    DateTime? dueAt,
    bool? isDone,
    DateTime? updatedAt,
  }) => Task(
    id: id,
    coupleId: coupleId,
    title: title ?? this.title,
    note: note ?? this.note,
    dueAt: dueAt ?? this.dueAt,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
