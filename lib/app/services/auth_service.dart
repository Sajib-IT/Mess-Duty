import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

void _logFcm(String msg) {
  if (kDebugMode) dev.log('[FCMToken] $msg', name: 'MessDuty');
}

class AuthService extends GetxService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection(Collections.users).doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(Collections.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final token = await _fcm.getToken();
    _logFcm('📱 Device FCM token (signUp): $token');
    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      fcmToken: token,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(Collections.users).doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final token = await _fcm.getToken();
    _logFcm('📱 Device FCM token (signIn): $token');
    await _firestore.collection(Collections.users).doc(uid).update({'fcmToken': token});
    return getUserModel(uid);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection(Collections.users).doc(uid).update({'fcmToken': null});
    }
    await _auth.signOut();
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (updates.isNotEmpty) {
      await _firestore.collection(Collections.users).doc(uid).update(updates);
    }
  }

  Future<void> toggleAway(String uid, bool isAway, DateTime? awayUntil) async {
    await _firestore.collection(Collections.users).doc(uid).update({
      'isAway': isAway,
      'awayUntil': awayUntil != null ? Timestamp.fromDate(awayUntil) : null,
    });
  }
}

