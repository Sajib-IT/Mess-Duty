import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../models/task_models.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key});
  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  TaskModel? task;
  late TaskController taskCtrl;
  List<Map<String, dynamic>> groups = <Map<String, dynamic>>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    taskCtrl = Get.find<TaskController>();
    // Safely cast arguments — null when opened from AppBar without a task
    task = Get.arguments is TaskModel ? Get.arguments as TaskModel : null;
    if (task != null) _initGroups();
  }

  void _loadTask(TaskModel selected) {
    setState(() {
      task = selected;
      _initGroups();
    });
  }

  void _initGroups() {
    final existing = taskCtrl.getGroupsForTask(task!.taskId);
    if (existing.isNotEmpty) {
      groups = existing.map((g) => <String, dynamic>{
        'label': g.label,
        'memberIds': List<String>.from(g.memberIds),
      }).toList();
    } else {
      groups = <Map<String, dynamic>>[
        <String, dynamic>{
          'label': task!.displayLabel,
          'memberIds': List<String>.from(taskCtrl.members.map((m) => m.uid)),
        },
      ];
    }
  }

  void _addGroup() {
    setState(() {
      groups.add(<String, dynamic>{
        'label': 'Group ${groups.length + 1}',
        'memberIds': <String>[],
      });
    });
  }

  void _removeGroup(int i) {
    setState(() => groups.removeAt(i));
  }

  void _toggleMember(int groupIdx, String uid) {
    setState(() {
      final ids = groups[groupIdx]['memberIds'] as List<String>;
      if (ids.contains(uid)) {
        ids.remove(uid);
      } else {
        ids.add(uid);
      }
    });
  }

  Future<void> _save() async {
    if (task == null) return;
    setState(() => _saving = true);
    try {
      await taskCtrl.updateTaskGroups(task!.taskId, groups);
      Get.snackbar(
        '✅ Saved',
        'Task configuration updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
      await Future.delayed(const Duration(milliseconds: 1800));
      Get.back();
    } catch (e) {
      Get.snackbar(
        '❌ Failed',
        'Could not save configuration. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── No task selected yet: show task picker ─────────────────────────────
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Configure Task'),
        ),
        body: Obx(() {
          final tasks = taskCtrl.tasks;
          if (tasks.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.task_outlined,
              title: 'No tasks found',
              subtitle: 'Tasks are created automatically when a mess is set up.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select a task to configure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final t = tasks[i];
                    final color = _taskColor(t.taskType);
                    final groups = taskCtrl.getGroupsForTask(t.taskId);
                    return InkWell(
                      onTap: () => _loadTask(t),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(t.displayIcon, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.displayLabel,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${groups.length} group${groups.length != 1 ? 's' : ''}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      );
    }

    // ── Task selected: show group configurator ─────────────────────────────
    final members = taskCtrl.members;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Row(
          children: [
            Text(task!.displayIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(task!.displayLabel),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Split members into groups. Each group rotates independently. Useful for multiple bathrooms, etc.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...List.generate(
                  groups.length,
                  (i) => _GroupCard(
                    groupIndex: i,
                    groupData: groups[i],
                    members: members,
                    onRemove: groups.length > 1 ? () => _removeGroup(i) : null,
                    onToggleMember: (uid) => _toggleMember(i, uid),
                    onLabelChanged: (v) => setState(() => groups[i]['label'] = v),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Group'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Configuration'),
          ),
        ),
      ),
    );
  }

  static Color _taskColor(TaskType type) {
    switch (type) {
      case TaskType.teaMaking: return AppColors.teaMaking;
      case TaskType.bathroomCleaning: return AppColors.bathroomCleaning;
      case TaskType.basinCleaning: return AppColors.basinCleaning;
      case TaskType.waterFilterRefill: return AppColors.waterFilter;
      case TaskType.garbageDisposal: return AppColors.garbageDisposal;
      case TaskType.custom: return AppColors.customTask;
    }
  }
}

class _GroupCard extends StatelessWidget {
  final int groupIndex;
  final Map<String, dynamic> groupData;
  final List<UserModel> members;
  final VoidCallback? onRemove;
  final Function(String uid) onToggleMember;
  final Function(String label) onLabelChanged;

  const _GroupCard({
    required this.groupIndex,
    required this.groupData,
    required this.members,
    this.onRemove,
    required this.onToggleMember,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIds = groupData['memberIds'] as List<String>;
    final selectedCount = members.where((m) => selectedIds.contains(m.uid)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group name row ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: groupData['label'] as String,
                    onChanged: onLabelChanged,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      isDense: true,
                      prefixIcon: const Icon(Icons.group_outlined, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: onRemove,
                    tooltip: 'Remove Group',
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Members header ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$selectedCount / ${members.length} selected',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── Member list ───────────────────────────────────────────
            ...members.map((m) {
              final selected = selectedIds.contains(m.uid);
              return InkWell(
                onTap: () => onToggleMember(m.uid),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar with away badge
                      Stack(
                        children: [
                          AppAvatar(
                            photoUrl: m.photoUrl,
                            name: m.name,
                            radius: 20,
                            backgroundColor: selected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                          ),
                          if (m.isAway)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Text('🏖️', style: TextStyle(fontSize: 9)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Name + status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: selected ? AppColors.primary : Colors.black87,
                              ),
                            ),
                            if (m.isAway)
                              Text(
                                'Away — skipped in rotation',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Check indicator
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: selected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 22,
                                key: ValueKey('checked'))
                            : Icon(Icons.radio_button_unchecked,
                                color: Colors.grey.shade400, size: 22,
                                key: const ValueKey('unchecked')),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


