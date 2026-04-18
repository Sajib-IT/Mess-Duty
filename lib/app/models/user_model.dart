import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? messId;
  final String? fcmToken;
  final bool isAway;
  final DateTime? awayUntil;
  final DateTime createdAt;
  final int totalDutiesDone;
  final int daysInMess;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.messId,
    this.fcmToken,
    this.isAway = false,
    this.awayUntil,
    required this.createdAt,
    this.totalDutiesDone = 0,
    this.daysInMess = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      messId: data['messId'],
      fcmToken: data['fcmToken'],
      isAway: data['isAway'] ?? false,
      awayUntil: data['awayUntil'] != null
          ? (data['awayUntil'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalDutiesDone: data['totalDutiesDone'] ?? 0,
      daysInMess: data['daysInMess'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'messId': messId,
        'fcmToken': fcmToken,
        'isAway': isAway,
        'awayUntil': awayUntil != null ? Timestamp.fromDate(awayUntil!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'totalDutiesDone': totalDutiesDone,
        'daysInMess': daysInMess,
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? messId,
    String? fcmToken,
    bool? isAway,
    DateTime? awayUntil,
    int? totalDutiesDone,
    int? daysInMess,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        messId: messId ?? this.messId,
        fcmToken: fcmToken ?? this.fcmToken,
        isAway: isAway ?? this.isAway,
        awayUntil: awayUntil ?? this.awayUntil,
        createdAt: createdAt,
        totalDutiesDone: totalDutiesDone ?? this.totalDutiesDone,
        daysInMess: daysInMess ?? this.daysInMess,
      );
}

