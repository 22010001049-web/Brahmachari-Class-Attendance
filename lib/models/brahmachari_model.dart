/// Represents a single brahmachari (student) in the database.
///
/// Maps directly to the `brahmacharis` database table.
class BrahmachariModel {
  final String? id;
  final String name;
  final DateTime? createdAt;

  BrahmachariModel({
    this.id,
    required this.name,
    this.createdAt,
  });

  /// Creates a [BrahmachariModel] from a JSON map (database row).
  factory BrahmachariModel.fromJson(Map<String, dynamic> json) {
    return BrahmachariModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts a [BrahmachariModel] to a JSON map for database operations.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
    };
    if (id != null) {
      data['id'] = id;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    return data;
  }

  BrahmachariModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return BrahmachariModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'BrahmachariModel(id: $id, name: $name)';
}
