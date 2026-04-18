import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final obscure = true.obs;
    final obscureConfirm = true.obs;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Profile photo picker
                          Obx(() => GestureDetector(
                                onTap: ctrl.pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 56,
                                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                                      backgroundImage: ctrl.selectedImage.value != null
                                          ? FileImage(ctrl.selectedImage.value!)
                                          : null,
                                      child: ctrl.selectedImage.value == null
                                          ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add profile photo',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: nameCtrl,
                            validator: (v) => Validators.required(v, 'Name'),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Obx(() => TextFormField(
                                controller: passCtrl,
                                obscureText: obscure.value,
                                validator: Validators.password,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(obscure.value ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => obscure.toggle(),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 14),
                          Obx(() => TextFormField(
                                controller: confirmPassCtrl,
                                obscureText: obscureConfirm.value,
                                validator: (v) {
                                  if (v != passCtrl.text) return 'Passwords do not match';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(obscureConfirm.value ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => obscureConfirm.toggle(),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 28),
                          Obx(() => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: ctrl.isLoading.value
                                      ? null
                                      : () {
                                          if (formKey.currentState!.validate()) {
                                            ctrl.signUp(
                                              name: nameCtrl.text.trim(),
                                              email: emailCtrl.text.trim(),
                                              phone: phoneCtrl.text.trim(),
                                              password: passCtrl.text,
                                            );
                                          }
                                        },
                                  child: ctrl.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Create Account'),
                                ),
                              )),
                          Obx(() => ctrl.errorMessage.value.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    ctrl.errorMessage.value,
                                    style: const TextStyle(color: AppColors.error),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox()),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


