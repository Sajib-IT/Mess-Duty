enum TaskType { event, daily, weekly }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final List<String> membersOrder; // List of UIDs
  final int rotationIndex;
  final DateTime? lastAssignedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.membersOrder,
    this.rotationIndex = 0,
    this.lastAssignedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> data, String id) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.toString() == 'TaskType.${data['type']}',
        orElse: () => TaskType.event,
      ),
      membersOrder: List<String>.from(data['membersOrder'] ?? []),
      rotationIndex: data['rotationIndex'] ?? 0,
      lastAssignedAt: data['lastAssignedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastAssignedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'membersOrder': membersOrder,
      'rotationIndex': rotationIndex,
      'lastAssignedAt': lastAssignedAt?.millisecondsSinceEpoch,
    };
  }

  TaskModel copyWith({
    int? rotationIndex,
    DateTime? lastAssignedAt,
    List<String>? membersOrder,
  }) {
    return TaskModel(
      id: this.id,
      title: this.title,
      description: this.description,
      type: this.type,
      membersOrder: membersOrder ?? this.membersOrder,
      rotationIndex: rotationIndex ?? this.rotationIndex,
      lastAssignedAt: lastAssignedAt ?? this.lastAssignedAt,
    );
  }
}
