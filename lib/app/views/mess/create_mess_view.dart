import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';

class CreateMessView extends StatelessWidget {
  const CreateMessView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MessController>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Mess')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.home_work, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Set Up Your Mess',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a mess to start managing duties with your roommates.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Mess Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                validator: (v) => Validators.required(v, 'Mess name'),
                decoration: const InputDecoration(
                  labelText: 'Mess Name',
                  hintText: 'e.g. Green Hostel Mess',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: addressCtrl,
                validator: (v) => Validators.required(v, 'Address'),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. Block C, Room 304',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of the mess...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Default tasks (Tea Making, Bathroom Cleaning, Basin Cleaning, Water Filter Refill, Garbage Disposal) will be created automatically.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isLoading.value
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                await ctrl.createMess(
                                  name: nameCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                );
                              }
                            },
                      icon: ctrl.isLoading.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Create Mess'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}



