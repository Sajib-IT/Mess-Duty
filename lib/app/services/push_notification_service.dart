import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../utils/app_constants.dart';

/// Sends push notifications via the custom FCM relay server.
/// API: POST https://push-server.onrender.com/send
///   { "token": "...", "title": "...", "body": "..." }
class PushNotificationService extends GetxService {
  static const _apiUrl = 'https://push-server.onrender.com/send-notification';
  final _firestore = FirebaseFirestore.instance;

  /// Fetch a user's FCM token from Firestore, then call the push API.
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final token = await _getFcmToken(userId);
      if (token == null || token.isEmpty) return false;
      return await sendToToken(token: token, title: title, body: body);
    } catch (e) {
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
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'title': title, 'body': body}),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
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
    final doc = await _firestore.collection(Collections.users).doc(userId).get();
    return doc.data()?['fcmToken'] as String?;
  }
}


