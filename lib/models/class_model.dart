/// Represents a class in the application database.
///
/// Maps directly to the `classes` database table.
class ClassModel {
  final String? id;
  final String speakerName;
  final String classDate; // Format: 'YYYY-MM-DD'
  final String startTime; // Format: 'HH:MM:SS'
  final DateTime? createdAt;

  ClassModel({
    this.id,
    required this.speakerName,
    required this.classDate,
    required this.startTime,
    this.createdAt,
  });

  /// Creates a [ClassModel] from a JSON map (database row).
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String?,
      speakerName: json['speaker_name'] as String,
      classDate: json['class_date'] as String,
      startTime: json['start_time'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts a [ClassModel] to a JSON map for database operations.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'speaker_name': speakerName,
      'class_date': classDate,
      'start_time': startTime,
    };
    if (id != null) {
      data['id'] = id;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    return data;
  }

  ClassModel copyWith({
    String? id,
    String? speakerName,
    String? classDate,
    String? startTime,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      speakerName: speakerName ?? this.speakerName,
      classDate: classDate ?? this.classDate,
      startTime: startTime ?? this.startTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, speakerName: $speakerName, classDate: $classDate, startTime: $startTime)';
  }
}
