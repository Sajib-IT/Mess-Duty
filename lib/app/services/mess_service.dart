import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/mess_model.dart';
import '../models/user_model.dart';
import '../models/other_models.dart';
import '../utils/app_constants.dart';

class MessService extends GetxService {
  final _firestore = FirebaseFirestore.instance;

  Future<MessModel> createMess({
    required String name,
    required String address,
    required String description,
    required String createdBy,
  }) async {
    final ref = _firestore.collection(Collections.messes).doc();
    final mess = MessModel(
      messId: ref.id,
      name: name,
      address: address,
      description: description,
      createdBy: createdBy,
      memberIds: [createdBy],
      createdAt: DateTime.now(),
    );
    final batch = _firestore.batch();
    batch.set(ref, mess.toMap());
    batch.update(_firestore.collection(Collections.users).doc(createdBy), {
      'messId': ref.id,
      'daysInMess': 0,
    });
    await batch.commit();
    return mess;
  }

  Stream<MessModel?> getMessStream(String messId) {
    return _firestore
        .collection(Collections.messes)
        .doc(messId)
        .snapshots()
        .map((doc) => doc.exists ? MessModel.fromFirestore(doc) : null);
  }

  Future<MessModel?> getMess(String messId) async {
    final doc = await _firestore.collection(Collections.messes).doc(messId).get();
    return doc.exists ? MessModel.fromFirestore(doc) : null;
  }

  Stream<List<UserModel>> getMembersStream(String messId) {
    return _firestore
        .collection(Collections.users)
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    final results = await _firestore
        .collection(Collections.users)
        .where('messId', isNull: true)
        .get();

    return results.docs
        .map((d) => UserModel.fromFirestore(d))
        .where((u) =>
            u.name.toLowerCase().contains(lowerQuery) ||
            u.email.toLowerCase().contains(lowerQuery))
        .take(20)
        .toList();
  }

  Future<void> sendInvitation({
    required String messId,
    required String messName,
    required String invitedBy,
    required String invitedByName,
    required String invitedUserId,
  }) async {
    // Check no pending invitation exists
    final existing = await _firestore
        .collection(Collections.invitations)
        .where('messId', isEqualTo: messId)
        .where('invitedUserId', isEqualTo: invitedUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) return;

    final ref = _firestore.collection(Collections.invitations).doc();
    final invitation = InvitationModel(
      invitationId: ref.id,
      messId: messId,
      messName: messName,
      invitedBy: invitedBy,
      invitedByName: invitedByName,
      invitedUserId: invitedUserId,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );
    await ref.set(invitation.toMap());

    // Create in-app notification
    final notifRef = _firestore.collection(Collections.notifications).doc();
    await notifRef.set({
      'userId': invitedUserId,
      'messId': messId,
      'title': 'Mess Invitation',
      'body': '$invitedByName invited you to join $messName',
      'type': 'invitation',
      'relatedId': ref.id,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> acceptInvitation(InvitationModel invitation) async {
    final batch = _firestore.batch();
    // Update invitation
    batch.update(
      _firestore.collection(Collections.invitations).doc(invitation.invitationId),
      {'status': 'accepted'},
    );
    // Add user to mess
    batch.update(
      _firestore.collection(Collections.messes).doc(invitation.messId),
      {'memberIds': FieldValue.arrayUnion([invitation.invitedUserId])},
    );
    // Set messId on user
    batch.update(
      _firestore.collection(Collections.users).doc(invitation.invitedUserId),
      {'messId': invitation.messId, 'daysInMess': 0},
    );
    await batch.commit();
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore
        .collection(Collections.invitations)
        .doc(invitationId)
        .update({'status': 'declined'});
  }

  Stream<List<InvitationModel>> getPendingInvitationsStream(String userId) {
    return _firestore
        .collection(Collections.invitations)
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => InvitationModel.fromFirestore(d)).toList());
  }
}

