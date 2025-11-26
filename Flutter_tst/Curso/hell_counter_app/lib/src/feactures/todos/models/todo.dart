import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;

  Todo({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
  };

  static Todo fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, title, description, isCompleted];
}
