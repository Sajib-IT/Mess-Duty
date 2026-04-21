import 'package:get/get.dart';
import '../models/mess_model.dart';
import '../models/user_model.dart';
import '../models/other_models.dart';
import '../services/mess_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/push_notification_service.dart';
import '../services/notification_service.dart' show NotificationService;
import '../utils/app_constants.dart';
import '../routes/app_routes.dart';

class MessController extends GetxController {
  final _messService = Get.find<MessService>();
  final _authService = Get.find<AuthService>();
  PushNotificationService? get _push => Get.isRegistered<PushNotificationService>()
      ? Get.find<PushNotificationService>()
      : null;
  NotificationService? get _notif => Get.isRegistered<NotificationService>()
      ? Get.find<NotificationService>()
      : null;

  final currentMess = Rxn<MessModel>();
  final members = <UserModel>[].obs;
  final searchResults = <UserModel>[].obs;
  final pendingInvitations = <InvitationModel>[].obs;
  final isLoading = false.obs;
  final isSearching = false.obs;

  // Members selected during mess creation
  final selectedMembers = <UserModel>[].obs;

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  final isRefreshing = false.obs;

  Future<void> refresh() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final messId = currentMess.value?.messId;
      if (messId != null) loadMess(messId);
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      isRefreshing.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserMess();
    _listenInvitations();
  }

  void _loadUserMess() async {
    final user = await _authService.getUserModel(currentUid);
    if (user?.messId != null) {
      loadMess(user!.messId!);
    }
  }

  void _listenInvitations() {
    if (currentUid.isEmpty) return;
    _messService.getPendingInvitationsStream(currentUid).listen((invites) {
      pendingInvitations.value = invites;
    });
  }

  void loadMess(String messId) {
    _messService.getMessStream(messId).listen((mess) {
      currentMess.value = mess;
    });
    _messService.getMembersStream(messId).listen((m) {
      members.value = m;
    });
  }

  Future<void> createMess({
    required String name,
    required String address,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      final mess = await _messService.createMess(
        name: name,
        address: address,
        description: description,
        createdBy: currentUid,
        initialMemberIds: selectedMembers.map((u) => u.uid).toList(),
      );
      // Initialize default tasks with all members
      final taskService = Get.find<TaskService>();
      await taskService.initializeDefaultTasks(mess.messId, mess.memberIds);
      selectedMembers.clear();
      currentMess.value = mess;
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelectMember(UserModel user) {
    if (selectedMembers.any((m) => m.uid == user.uid)) {
      selectedMembers.removeWhere((m) => m.uid == user.uid);
    } else {
      selectedMembers.add(user);
    }
  }

  bool isMemberSelected(String uid) => selectedMembers.any((m) => m.uid == uid);

  Future<void> searchUsers(String query) async {
    isSearching.value = true;
    searchResults.value = await _messService.searchUsers(query);
    isSearching.value = false;
  }

  Future<void> inviteUser(UserModel user) async {
    try {
      final mess = currentMess.value;
      if (mess == null) return;
      final myName = members.firstWhere((m) => m.uid == currentUid).name;
      await _messService.sendInvitation(
        messId: mess.messId,
        messName: mess.name,
        invitedBy: currentUid,
        invitedByName: myName,
        invitedUserId: user.uid,
      );

      // Push notification to invited user
      await _push?.sendToUser(
        userId: user.uid,
        title: '📨 Mess Invitation',
        body: '$myName invited you to join "${mess.name}". Open the app to accept or decline.',
      );

      // In-app notification to invited user
      await _notif?.createInAppNotification(
        userId: user.uid,
        messId: mess.messId,
        title: '📨 You have a mess invitation!',
        body: '$myName invited you to join "${mess.name}". Tap to accept or decline.',
        type: NotificationType.invitation,
        relatedId: mess.messId,
      );

      Get.snackbar(
        '✅ Invitation Sent',
        '${user.name} has been invited to "${mess.name}".',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> acceptInvitation(InvitationModel invitation) async {
    try {
      await _messService.acceptInvitation(invitation);
      loadMess(invitation.messId);
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    await _messService.declineInvitation(invitationId);
  }
}



