import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileController extends GetxController {
  final _authService = Get.find<AuthService>();

  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final selectedImage = Rxn<File>();

  String get currentUid => _authService.currentFirebaseUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (currentUid.isNotEmpty) {
      _authService.getUserStream(currentUid).listen((u) => user.value = u);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) selectedImage.value = File(picked.path);
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    try {
      isLoading.value = true;
      await _authService.updateProfile(
        uid: currentUid,
        name: name,
        phone: phone,
        imageFile: selectedImage.value,
      );
      Get.snackbar('Success', 'Profile updated!', snackPosition: SnackPosition.BOTTOM);
      selectedImage.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleAway(bool isAway, DateTime? awayUntil) async {
    await _authService.toggleAway(currentUid, isAway, awayUntil);
  }
}

