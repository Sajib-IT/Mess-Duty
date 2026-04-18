import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/other_models.dart' as app_models;
import '../utils/app_constants.dart';

/// Top-level handler for background FCM messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _showAwesomeNotification(
    title: message.notification?.title ?? 'Mess Duty',
    body: message.notification?.body ?? '',
    payload: message.data,
  );
}

Future<void> _showAwesomeNotification({
  required String title,
  required String body,
  Map<String, dynamic>? payload,
}) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      channelKey: NotificationService.channelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      payload: payload?.map((k, v) => MapEntry(k, v.toString())),
      criticalAlert: true,
    ),
  );
}

class NotificationService extends GetxService {
  static const channelKey = 'mess_duty_channel';
  static const channelName = 'Mess Duty Notifications';
  static const channelDesc = 'MessDuty duty reminders and alerts';

  final _firestore = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Initialize awesome_notifications
    await AwesomeNotifications().initialize(
      null, // null = use default app icon
      [
        NotificationChannel(
          channelGroupKey: 'mess_duty_group',
          channelKey: channelKey,
          channelName: channelName,
          channelDescription: channelDesc,
          defaultColor: const Color(0xFF00695C),
          ledColor: const Color(0xFF00695C),
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: highVibrationPattern,
          criticalAlerts: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'mess_duty_group',
          channelGroupName: 'Mess Duty',
        ),
      ],
      debug: false,
    );

    // Request permission
    await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.CriticalAlert,
      ],
    );

    // Set action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );

    // FCM setup
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // ── Awesome Notifications Handlers (must be static) ──────────────────────

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // Handle notification tap action — navigate based on payload
    final route = action.payload?['route'];
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction action) async {}

  // ── FCM Handlers ──────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    showLocalNotification(
      title: message.notification?.title ?? 'Mess Duty',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Show an immediate local notification with long vibration
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? route,
  }) async {
    final combinedPayload = <String, String>{
      if (payload != null) ...payload.map((k, v) => MapEntry(k, v.toString())),
      if (route != null) 'route': route,
    };

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: channelKey,
        title: '<b>$title</b>',
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: combinedPayload.isEmpty ? null : combinedPayload,
        criticalAlert: true,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
    );
  }

  /// Show a duty reminder notification with action buttons
  Future<void> showDutyReminderNotification({
    required String title,
    required String body,
    required String rotationId,
    required String messId,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: channelKey,
        title: '⏰ <b>$title</b>',
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: {'rotationId': rotationId, 'messId': messId},
        criticalAlert: true,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        color: const Color(0xFF00695C),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_DONE',
          label: '✅ Mark Done',
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: '⏱ Remind Later',
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  /// Schedule a reminder notification at a specific date/time
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: '⏰ <b>$title</b>',
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
        criticalAlert: true,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        color: const Color(0xFF00695C),
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ── Firestore In-App Notifications ───────────────────────────────────────

  Future<void> createInAppNotification({
    required String userId,
    required String messId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    await _firestore.collection(Collections.notifications).add({
      'userId': userId,
      'messId': messId,
      'title': title,
      'body': body,
      'type': type.value,      'relatedId': relatedId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<app_models.NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(Collections.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => app_models.NotificationModel.fromFirestore(d)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(Collections.notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection(Collections.notifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}





