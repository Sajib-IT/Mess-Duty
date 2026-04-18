import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

class TaskModel {
  final String taskId;
  final String messId;
  final TaskType taskType;
  final List<String> groupIds;
  final bool isActive;
  final DateTime? reminderTime;

  TaskModel({
    required this.taskId,
    required this.messId,
    required this.taskType,
    required this.groupIds,
    this.isActive = true,
    this.reminderTime,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      taskId: doc.id,
      messId: data['messId'] ?? '',
      taskType: taskTypeFromString(data['taskType'] ?? ''),
      groupIds: List<String>.from(data['groupIds'] ?? []),
      isActive: data['isActive'] ?? true,
      reminderTime: data['reminderTime'] != null
          ? (data['reminderTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'messId': messId,
        'taskType': taskType.value,
        'groupIds': groupIds,
        'isActive': isActive,
        'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      };
}

class TaskGroupModel {
  final String groupId;
  final String taskId;
  final String messId;
  final List<String> memberIds;
  final int currentRotationIndex;
  final String label;

  TaskGroupModel({
    required this.groupId,
    required this.taskId,
    required this.messId,
    required this.memberIds,
    this.currentRotationIndex = 0,
    required this.label,
  });

  factory TaskGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskGroupModel(
      groupId: doc.id,
      taskId: data['taskId'] ?? '',
      messId: data['messId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      currentRotationIndex: data['currentRotationIndex'] ?? 0,
      label: data['label'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'messId': messId,
        'memberIds': memberIds,
        'currentRotationIndex': currentRotationIndex,
        'label': label,
      };
}

class DutyRotationModel {
  final String rotationId;
  final String groupId;
  final String taskId;
  final String messId;
  final String assignedUserId;
  final DateTime scheduledDate;
  final RotationStatus status;
  final DateTime createdAt;

  DutyRotationModel({
    required this.rotationId,
    required this.groupId,
    required this.taskId,
    required this.messId,
    required this.assignedUserId,
    required this.scheduledDate,
    required this.status,
    required this.createdAt,
  });

  factory DutyRotationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DutyRotationModel(
      rotationId: doc.id,
      groupId: data['groupId'] ?? '',
      taskId: data['taskId'] ?? '',
      messId: data['messId'] ?? '',
      assignedUserId: data['assignedUserId'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: rotationStatusFromString(data['status'] ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'taskId': taskId,
        'messId': messId,
        'assignedUserId': assignedUserId,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DutyRotationModel copyWith({RotationStatus? status}) => DutyRotationModel(
        rotationId: rotationId,
        groupId: groupId,
        taskId: taskId,
        messId: messId,
        assignedUserId: assignedUserId,
        scheduledDate: scheduledDate,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

class TaskCompletionModel {
  final String completionId;
  final String rotationId;
  final String taskId;
  final String messId;
  final String requestedBy;
  final List<String> acceptedBy;
  final int requiredAcceptances;
  final CompletionStatus status;
  final DateTime requestedAt;
  final DateTime? completedAt;

  TaskCompletionModel({
    required this.completionId,
    required this.rotationId,
    required this.taskId,
    required this.messId,
    required this.requestedBy,
    required this.acceptedBy,
    this.requiredAcceptances = 2,
    required this.status,
    required this.requestedAt,
    this.completedAt,
  });

  factory TaskCompletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCompletionModel(
      completionId: doc.id,
      rotationId: data['rotationId'] ?? '',
      taskId: data['taskId'] ?? '',
      messId: data['messId'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      acceptedBy: List<String>.from(data['acceptedBy'] ?? []),
      requiredAcceptances: data['requiredAcceptances'] ?? 2,
      status: completionStatusFromString(data['status'] ?? ''),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'rotationId': rotationId,
        'taskId': taskId,
        'messId': messId,
        'requestedBy': requestedBy,
        'acceptedBy': acceptedBy,
        'requiredAcceptances': requiredAcceptances,
        'status': status.value,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}

