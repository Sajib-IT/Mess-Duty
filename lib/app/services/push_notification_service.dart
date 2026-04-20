import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../utils/app_constants.dart';
import 'dart:developer' as dev;

/// Sends push notifications via the custom FCM relay server.
/// API: POST https://push-server.onrender.com/send-notification
///   { "token": "...", "title": "...", "body": "..." }
class PushNotificationService extends GetxService {
  static const _apiUrl = 'https://mess-duty-push-notification-backend.vercel.app/send-notification';
  final _firestore = FirebaseFirestore.instance;

  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    if (kDebugMode) {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          dev.log('📤 Sending push → ${options.uri}', name: 'MessDuty');
          dev.log('   payload : ${options.data}', name: 'MessDuty');
          handler.next(options);
        },
        onResponse: (response, handler) {
          dev.log('📬 Response status : ${response.statusCode}', name: 'MessDuty');
          dev.log('   Response body   : ${response.data}', name: 'MessDuty');
          if ((response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300) {
            dev.log('✅ Push sent successfully', name: 'MessDuty');
          }
          handler.next(response);
        },
        onError: (DioException e, handler) {
          dev.log('❌ Push error: ${e.message}', name: 'MessDuty');
          handler.next(e);
        },
      ));
    }
  }

  /// Fetch a user's FCM token from Firestore, then call the push API.
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final token = await _getFcmToken(userId);
      if (kDebugMode) {
        dev.log('[PushNotification] 🔑 FCM token for userId $userId → $token', name: 'MessDuty');
      }
      if (token == null || token.isEmpty) return false;
      return await sendToToken(token: token, title: title, body: body);
    } catch (e) {
      if (kDebugMode) dev.log('[PushNotification] ❌ sendToUser error: $e', name: 'MessDuty');
      return false;
    }
  }

  /// Send directly to a known FCM token.
  Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.post(
        _apiUrl,
        data: {'fcmToken': token, 'title': title, 'body': body},
      );
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      if (kDebugMode) dev.log('[PushNotification] ❌ DioException: ${e.message}', name: 'MessDuty');
      return false;
    } catch (e) {
      if (kDebugMode) dev.log('[PushNotification] ❌ sendToToken error: $e', name: 'MessDuty');
      return false;
    }
  }

  /// Send to a list of user IDs (e.g. all mess members except self).
  Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
  }) async {
    final futures = userIds.map((uid) => sendToUser(userId: uid, title: title, body: body));
    await Future.wait(futures);
  }

  /// Look up the FCM token stored on the user document.
  Future<String?> _getFcmToken(String userId) async {
    if (kDebugMode) {
      dev.log('[PushNotification] 🔍 Firestore fcmToken lookup for $userId', name: 'MessDuty');
    }
    final doc = await _firestore.collection(Collections.users).doc(userId).get();
    final token = doc.data()?['fcmToken'] as String?;
    if (kDebugMode) {
      dev.log('[PushNotification] 🔍 → token: $token', name: 'MessDuty');
    }
    return token;
  }
}

