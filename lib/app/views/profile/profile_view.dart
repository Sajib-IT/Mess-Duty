import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/phone_field.dart';
import '../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProfileController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      body: Obx(() {
        final user = ctrl.user.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primary,
              title: const Text('Profile'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _confirmSignOut(context, authCtrl),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primaryLight],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      GestureDetector(
                        onTap: () => _editProfile(context, ctrl, user),
                        child: Stack(
                          children: [
                            AppAvatar(
                              photoUrl: user.photoUrl,
                              name: user.name,
                              radius: 50,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _StatBadge(
                          value: '${user.totalDutiesDone}',
                          label: 'Duties Done',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _StatBadge(
                          value: '${user.daysInMess}',
                          label: 'Days in Mess',
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        _StatBadge(
                          value: user.isAway ? 'Away' : 'Active',
                          label: 'Status',
                          color: user.isAway ? AppColors.warning : AppColors.success,
                        ),
                      ],
                    ),
                  ),

                  // Info card
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        _InfoTile(icon: Icons.person, label: 'Full Name', value: user.name),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(icon: Icons.email, label: 'Email', value: user.email),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(icon: Icons.phone, label: 'Phone', value: user.phone),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.calendar_today,
                          label: 'Member Since',
                          value: AppHelpers.formatDate(user.createdAt),
                        ),
                      ],
                    ),
                  ),

                  // Away status
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flight_takeoff, color: AppColors.warning),
                      ),
                      title: const Text('Mark as Away',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        user.isAway
                            ? user.awayUntil != null
                                ? 'Until ${AppHelpers.formatDate(user.awayUntil!)}'
                                : 'Currently away'
                            : 'Rotation will skip you when away',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: user.isAway,
                      activeThumbColor: AppColors.warning,
                      onChanged: (v) async {
                        if (v) {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          ctrl.toggleAway(true, date);
                        } else {
                          ctrl.toggleAway(false, null);
                        }
                      },
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _editProfile(context, ctrl, user),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmSignOut(context, authCtrl),
                            icon: const Icon(Icons.logout, color: AppColors.error),
                            label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmSignOut(BuildContext context, AuthController authCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authCtrl.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, ProfileController ctrl, dynamic user) {
    final nameCtrl = TextEditingController(text: user.name);
    // Parse existing phone into dial code + local number
    final parsed = PhoneField.parse(user.phone ?? '');
    final phoneCtrl = TextEditingController(text: parsed.value);
    final selectedDialCode = parsed.key.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            Obx(() => PhoneField(
                  controller: phoneCtrl,
                  initialDialCode: selectedDialCode.value,
                  onDialCodeChanged: (code) => selectedDialCode.value = code,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    return null;
                  },
                )),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading.value
                        ? null
                        : () {
                            ctrl.updateProfile(
                              name: nameCtrl.text.trim(),
                              phone: PhoneField.combine(
                                selectedDialCode.value,
                                phoneCtrl.text.trim(),
                              ),
                            );
                            Get.back();
                          },
                    child: ctrl.isLoading.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBadge({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}



