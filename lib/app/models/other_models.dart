import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

class InvitationModel {
  final String invitationId;
  final String messId;
  final String messName;
  final String invitedBy;
  final String invitedByName;
  final String invitedUserId;
  final InvitationStatus status;
  final DateTime createdAt;

  InvitationModel({
    required this.invitationId,
    required this.messId,
    required this.messName,
    required this.invitedBy,
    required this.invitedByName,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
  });

  factory InvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvitationModel(
      invitationId: doc.id,
      messId: data['messId'] ?? '',
      messName: data['messName'] ?? '',
      invitedBy: data['invitedBy'] ?? '',
      invitedByName: data['invitedByName'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      status: invitationStatusFromString(data['status'] ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'messId': messId,
        'messName': messName,
        'invitedBy': invitedBy,
        'invitedByName': invitedByName,
        'invitedUserId': invitedUserId,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class ReminderModel {
  final String reminderId;
  final String rotationId;
  final String messId;
  final String setBy;
  final String targetUserId;
  final DateTime reminderTime;
  final bool isRepeating;
  final bool isActive;

  ReminderModel({
    required this.reminderId,
    required this.rotationId,
    required this.messId,
    required this.setBy,
    required this.targetUserId,
    required this.reminderTime,
    this.isRepeating = false,
    this.isActive = true,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      reminderId: doc.id,
      rotationId: data['rotationId'] ?? '',
      messId: data['messId'] ?? '',
      setBy: data['setBy'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      reminderTime: (data['reminderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRepeating: data['isRepeating'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'rotationId': rotationId,
        'messId': messId,
        'setBy': setBy,
        'targetUserId': targetUserId,
        'reminderTime': Timestamp.fromDate(reminderTime),
        'isRepeating': isRepeating,
        'isActive': isActive,
      };
}

class NotificationModel {
  final String notificationId;
  final String userId;
  final String messId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.messId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] ?? '',
      messId: data['messId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: notificationTypeFromString(data['type'] ?? ''),
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'messId': messId,
        'title': title,
        'body': body,
        'type': type.value,
        'relatedId': relatedId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

