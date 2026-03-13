import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_authService.user);
    ever(firebaseUser, _handleAuthChanged);
  }

  void _handleAuthChanged(User? user) {
    if (user == null) {
      userModel.value = null;
      Get.offAllNamed('/login');
    } else {
      userModel.bindStream(_firestoreService.streamUser(user.uid));
      Get.offAllNamed('/dashboard');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signIn(email, password);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      isLoading.value = true;
      await _authService.signUp(email, password, name);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<void> toggleAvailability() async {
    if (userModel.value != null) {
      await _firestoreService.updateUserAvailability(
          userModel.value!.id, !userModel.value!.isAvailable);
    }
  }
}
