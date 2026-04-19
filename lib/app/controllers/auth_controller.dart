import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final _authService = Get.find<AuthService>();

  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Wait until GetMaterialApp is fully mounted before listening to auth state.
    // This prevents "contextless navigation" errors when Firebase fires immediately.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _authService.authStateChanges.listen((user) async {
        if (user != null) {
          final userModel = await _authService.getUserModel(user.uid);
          currentUser.value = userModel;
          if (userModel != null) {
            final target = userModel.messId != null ? Routes.DASHBOARD : Routes.LANDING;
            if (Get.currentRoute != target) {
              Get.offAllNamed(target);
            }
          }
        } else {
          currentUser.value = null;
          if (Get.currentRoute != Routes.LOGIN) {
            Get.offAllNamed(Routes.LOGIN);
          }
        }
      });
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _authService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Sign up failed';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _authService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Sign in failed';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
