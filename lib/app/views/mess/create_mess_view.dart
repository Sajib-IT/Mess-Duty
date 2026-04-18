import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/shared_widgets.dart';

class CreateMessView extends StatefulWidget {
  const CreateMessView({super.key});
  @override
  State<CreateMessView> createState() => _CreateMessViewState();
}

class _CreateMessViewState extends State<CreateMessView> {
  final _ctrl = Get.find<MessController>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0 = details, 1 = members

  @override
  void initState() {
    super.initState();
    _ctrl.selectedMembers.clear();
    _ctrl.searchResults.clear();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => _step == 1 ? setState(() => _step = 0) : Get.back(),
                        ),
                        Text(
                          _step == 0 ? 'Create Mess' : 'Add Members',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Step indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _StepDot(index: 0, current: _step, label: 'Details'),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: _step >= 1 ? Colors.white : Colors.white38,
                            ),
                          ),
                          _StepDot(index: 1, current: _step, label: 'Members'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(_step == 0 ? -1 : 1, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
              child: _step == 0
                  ? _DetailsStep(key: const ValueKey(0), formKey: _formKey, nameCtrl: _nameCtrl, addressCtrl: _addressCtrl, descCtrl: _descCtrl)
                  : _MembersStep(key: const ValueKey(1), ctrl: _ctrl, searchCtrl: _searchCtrl),
            ),
          ),

          // ── Bottom button ────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Obx(() {
              final selectedCount = _ctrl.selectedMembers.length;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_step == 1 && selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.group, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '$selectedCount member${selectedCount != 1 ? 's' : ''} selected',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _ctrl.isLoading.value ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _ctrl.isLoading.value
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _step == 0 ? 'Next: Add Members' : 'Create Mess',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Icon(_step == 0 ? Icons.arrow_forward : Icons.check_circle_outline),
                              ],
                            ),
                    ),
                  ),
                  if (_step == 1)
                    TextButton(
                      onPressed: _ctrl.isLoading.value ? null : _createMess,
                      child: const Text('Skip & Create Without Members'),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (_step == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _step = 1);
      }
    } else {
      _createMess();
    }
  }

  void _createMess() {
    _ctrl.createMess(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
  }
}

// ── Step 1: Mess Details ──────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController descCtrl;

  const _DetailsStep({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Mess Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              validator: (v) => Validators.required(v, 'Mess name'),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Mess Name *',
                hintText: 'e.g. Green Hostel Block B',
                prefixIcon: Icon(Icons.home_work_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: addressCtrl,
              validator: (v) => Validators.required(v, 'Address'),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address *',
                hintText: 'e.g. Block C, Room 304, Campus Road',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description about this mess...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'In the next step you can search and add members directly. Default tasks (Tea Making, Bathroom Cleaning, etc.) will be auto-created.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Member Selection ──────────────────────────────────────────────────

class _MembersStep extends StatelessWidget {
  final MessController ctrl;
  final TextEditingController searchCtrl;

  const _MembersStep({super.key, required this.ctrl, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchCtrl,
            onChanged: (v) {
              if (v.trim().length >= 2) {
                ctrl.searchUsers(v.trim());
              } else if (v.trim().isEmpty) {
                ctrl.searchResults.clear();
              }
            },
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: Obx(() => ctrl.isSearching.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchCtrl.clear();
                            ctrl.searchResults.clear();
                          },
                        )
                      : const SizedBox()),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Selected members chips
        Obx(() {
          final selected = ctrl.selectedMembers;
          if (selected.isEmpty) return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Text('Added Members', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: selected.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: AppAvatar(photoUrl: selected[i].photoUrl, name: selected[i].name, radius: 12),
                      label: Text(selected[i].name.split(' ').first),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => ctrl.toggleSelectMember(selected[i]),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
          );
        }),

        // Search results
        Expanded(
          child: Obx(() {
            final results = ctrl.searchResults;
            if (results.isEmpty && searchCtrl.text.trim().length < 2) {
              return const EmptyStateWidget(
                icon: Icons.person_search,
                title: 'Search for members',
                subtitle: 'Type at least 2 characters to find users\nnot currently in any mess.',
              );
            }
            if (results.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.search_off,
                title: 'No users found',
                subtitle: 'Try a different name or email.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) => _MemberResultTile(user: results[i], ctrl: ctrl),
            );
          }),
        ),
      ],
    );
  }
}

class _MemberResultTile extends StatelessWidget {
  final UserModel user;
  final MessController ctrl;
  const _MemberResultTile({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.isMemberSelected(user.uid);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: AppAvatar(photoUrl: user.photoUrl, name: user.name, radius: 24),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected
                ? Container(
                    key: const ValueKey('check'),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  )
                : Container(
                    key: const ValueKey('add'),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary, size: 18),
                  ),
          ),
          onTap: () => ctrl.toggleSelectMember(user),
        ),
      );
    });
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;

  const _StepDot({required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final done = current > index;
    final active = current == index;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done || active ? Colors.white : Colors.white30,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? AppColors.primary : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active || done ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}
