import 'package:get/get.dart';
import '../models/mess_model.dart';
import '../models/user_model.dart';
import '../models/other_models.dart';
import '../services/mess_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../routes/app_routes.dart';

class MessController extends GetxController {
  final _messService = Get.find<MessService>();
  final _authService = Get.find<AuthService>();

  final currentMess = Rxn<MessModel>();
  final members = <UserModel>[].obs;
  final searchResults = <UserModel>[].obs;
  final pendingInvitations = <InvitationModel>[].obs;
  final isLoading = false.obs;
  final isSearching = false.obs;

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

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
      );
      // Initialize default tasks
      final taskService = Get.find<TaskService>();
      await taskService.initializeDefaultTasks(mess.messId, mess.memberIds);
      currentMess.value = mess;
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    isSearching.value = true;
    searchResults.value = await _messService.searchUsers(query);
    isSearching.value = false;
  }

  Future<void> inviteUser(UserModel user) async {
    try {
      final mess = currentMess.value;
      if (mess == null) return;
      await _messService.sendInvitation(
        messId: mess.messId,
        messName: mess.name,
        invitedBy: currentUid,
        invitedByName: members.firstWhere((m) => m.uid == currentUid).name,
        invitedUserId: user.uid,
      );
      Get.snackbar('Invited', '${user.name} has been invited!',
          snackPosition: SnackPosition.BOTTOM);
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



