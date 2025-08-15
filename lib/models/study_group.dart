import 'user.dart';

class StudyGroup {
  final int id;
  final String name;
  final String description;
  final User creator;
  final DateTime createdAt;

  StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.createdAt,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      creator: User.fromJson(json['creator']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
