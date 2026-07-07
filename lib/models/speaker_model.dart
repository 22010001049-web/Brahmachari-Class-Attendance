class SpeakerModel {
  final String? id;
  final String name;
  final DateTime? createdAt;

  SpeakerModel({
    this.id,
    required this.name,
    this.createdAt,
  });

  factory SpeakerModel.fromJson(Map<String, dynamic> json) {
    return SpeakerModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

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

  SpeakerModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return SpeakerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SpeakerModel(id: $id, name: $name)';
}
