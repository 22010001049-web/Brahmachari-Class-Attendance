/// Represents a single attendance record for a brahmachari in a class.
///
/// Maps directly to the `attendance` database table.
class AttendanceModel {
  final String? id;
  final String classId;
  final String brahmachariId;
  final String? arrivalTime; // Format: 'HH:MM:SS'
  final String status; // e.g. 'Present', 'Absent', 'Late'
  final DateTime? createdAt;

  AttendanceModel({
    this.id,
    required this.classId,
    required this.brahmachariId,
    this.arrivalTime,
    required this.status,
    this.createdAt,
  });

  /// Creates an [AttendanceModel] from a JSON map (database row).
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String?,
      classId: json['class_id'] as String,
      brahmachariId: json['brahmachari_id'] as String,
      arrivalTime: json['arrival_time'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts an [AttendanceModel] to a JSON map for database operations.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'class_id': classId,
      'brahmachari_id': brahmachariId,
      'arrival_time': arrivalTime,
      'status': status,
    };
    if (id != null) {
      data['id'] = id;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    return data;
  }

  AttendanceModel copyWith({
    String? id,
    String? classId,
    String? brahmachariId,
    String? arrivalTime,
    String? status,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      brahmachariId: brahmachariId ?? this.brahmachariId,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, classId: $classId, brahmachariId: $brahmachariId, status: $status)';
  }
}
