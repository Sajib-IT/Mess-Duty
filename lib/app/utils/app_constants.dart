class Collections {
  static const users = 'users';
  static const messes = 'messes';
  static const tasks = 'tasks';
  static const taskGroups = 'task_groups';
  static const dutyRotations = 'duty_rotations';
  static const taskCompletions = 'task_completions';
  static const reminders = 'reminders';
  static const notifications = 'notifications';
  static const invitations = 'invitations';
}

enum TaskType {
  teaMaking,
  bathroomCleaning,
  basinCleaning,
  waterFilterRefill,
  garbageDisposal,
}

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.teaMaking: return 'Tea Making';
      case TaskType.bathroomCleaning: return 'Bathroom Cleaning';
      case TaskType.basinCleaning: return 'Basin Cleaning';
      case TaskType.waterFilterRefill: return 'Water Filter Refill';
      case TaskType.garbageDisposal: return 'Garbage Disposal';
    }
  }

  String get icon {
    switch (this) {
      case TaskType.teaMaking: return '☕';
      case TaskType.bathroomCleaning: return '🚿';
      case TaskType.basinCleaning: return '🚰';
      case TaskType.waterFilterRefill: return '💧';
      case TaskType.garbageDisposal: return '🗑️';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

TaskType taskTypeFromString(String value) {
  return TaskType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => TaskType.teaMaking,
  );
}

enum RotationStatus { pending, inProgress, completed, skipped }
enum CompletionStatus { pending, approved, rejected }
enum InvitationStatus { pending, accepted, declined }
enum NotificationType {
  dutyReminder,
  manualReminder,
  completionRequest,
  completionApproved,
  completionRejected,
  invitation,
  invitationAccepted,
  memberJoined,
  memberLeft,
  dutySkipped,
  rotationStarted,
  messUpdated,
}

extension RotationStatusExt on RotationStatus {
  String get value => toString().split('.').last;
}
extension CompletionStatusExt on CompletionStatus {
  String get value => toString().split('.').last;
}
extension InvitationStatusExt on InvitationStatus {
  String get value => toString().split('.').last;
}
extension NotificationTypeExt on NotificationType {
  String get value => toString().split('.').last;
}

RotationStatus rotationStatusFromString(String v) =>
    RotationStatus.values.firstWhere((e) => e.value == v, orElse: () => RotationStatus.pending);
CompletionStatus completionStatusFromString(String v) =>
    CompletionStatus.values.firstWhere((e) => e.value == v, orElse: () => CompletionStatus.pending);
InvitationStatus invitationStatusFromString(String v) =>
    InvitationStatus.values.firstWhere((e) => e.value == v, orElse: () => InvitationStatus.pending);
NotificationType notificationTypeFromString(String v) =>
    NotificationType.values.firstWhere((e) => e.value == v, orElse: () => NotificationType.dutyReminder);

