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
  late TaskModel task;
  late TaskController taskCtrl;
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    taskCtrl = Get.find<TaskController>();
    task = Get.arguments as TaskModel;
    _initGroups();
  }

  void _initGroups() {
    final existing = taskCtrl.getGroupsForTask(task.taskId);
    if (existing.isNotEmpty) {
      groups = existing.map((g) => {
        'label': g.label,
        'memberIds': List<String>.from(g.memberIds),
      }).toList();
    } else {
      groups = [
        {'label': task.taskType.label, 'memberIds': List<String>.from(taskCtrl.members.map((m) => m.uid))},
      ];
    }
  }

  void _addGroup() {
    setState(() {
      groups.add({'label': 'Group ${groups.length + 1}', 'memberIds': <String>[]});
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
    await taskCtrl.updateTaskGroups(task.taskId, groups);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final members = taskCtrl.members;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configure: ${task.taskType.label}'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Column(
        children: [
          // Info
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
                ...List.generate(groups.length, (i) => _GroupCard(
                  groupIndex: i,
                  groupData: groups[i],
                  members: members,
                  onRemove: groups.length > 1 ? () => _removeGroup(i) : null,
                  onToggleMember: (uid) => _toggleMember(i, uid),
                  onLabelChanged: (v) => setState(() => groups[i]['label'] = v),
                )),
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
            onPressed: _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Save Configuration'),
          ),
        ),
      ),
    );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: groupData['label'] as String,
                    onChanged: onLabelChanged,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Members:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((m) {
                final selected = selectedIds.contains(m.uid);
                return FilterChip(
                  avatar: AppAvatar(photoUrl: m.photoUrl, name: m.name, radius: 12),
                  label: Text(m.name.split(' ').first),
                  selected: selected,
                  onSelected: (_) => onToggleMember(m.uid),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


