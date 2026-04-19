import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/history_controller.dart';
import '../../models/task_models.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../routes/app_routes.dart';
import 'package:mess_duty/app/views/tasks/tasks_view.dart';
import 'package:mess_duty/app/views/history/history_view.dart';
import 'package:mess_duty/app/views/profile/profile_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  late final MessController _messCtrl;
  late final TaskController _taskCtrl;
  late final AuthController _authCtrl;
  late final HistoryController _histCtrl;

  @override
  void initState() {
    super.initState();
    _messCtrl = Get.find<MessController>();
    _taskCtrl = Get.find<TaskController>();
    _authCtrl = Get.find<AuthController>();
    _histCtrl = Get.find<HistoryController>();

    // Initialize data after user model loads
    ever(_authCtrl.currentUser, (user) {
      if (user?.messId != null) {
        _messCtrl.loadMess(user!.messId!);
        _taskCtrl.initialize(user.messId!);
        _histCtrl.initialize(user.messId!);
      }
    });

    // Trigger initial if already loaded
    final user = _authCtrl.currentUser.value;
    if (user?.messId != null) {
      _messCtrl.loadMess(user!.messId!);
      _taskCtrl.initialize(user.messId!);
      _histCtrl.initialize(user.messId!);
    }
  }

  final _pages = <Widget>[
    const _DashboardHome(),
    const TasksView(),
    const HistoryView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ExitConfirmWrapper(
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Obx(() {
          final notifCtrl = Get.find<NotificationController>();
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              const BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
              const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.person),
                    if (notifCtrl.unreadCount.value > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Profile',
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final messCtrl = Get.find<MessController>();
    final taskCtrl = Get.find<TaskController>();
    final authCtrl = Get.find<AuthController>();
    final notifCtrl = Get.find<NotificationController>();
    final histCtrl = Get.find<HistoryController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              Obx(() => Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => Get.toNamed(Routes.NOTIFICATIONS),
                      ),
                      if (notifCtrl.unreadCount.value > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${notifCtrl.unreadCount.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                    ],
                  )),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Get.toNamed(Routes.MESS_SETTINGS),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Obx(() {
                          final user = authCtrl.currentUser.value;
                          final mess = messCtrl.currentMess.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_greeting()}, ${user?.name.split(' ').first ?? ''}!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (mess != null)
                                Text(
                                  mess.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                        // Member avatars
                        Obx(() {
                          final members = messCtrl.members;
                          return SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: members.length,
                              itemBuilder: (ctx, i) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: AppAvatar(
                                  photoUrl: members[i].photoUrl,
                                  name: members[i].name,
                                  radius: 18,
                                  backgroundColor: members[i].isAway
                                      ? Colors.grey
                                      : AppColors.primaryLight,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Obx(() {
                    final upcoming = taskCtrl.upcomingRotations;
                    final mine = upcoming.where((r) => r.assignedUserId == authCtrl.currentUser.value?.uid).length;
                    final pending = taskCtrl.completionRequests.length;
                    final completed = histCtrl.completedCount;

                    return Row(
                      children: [
                        _SummaryCard(
                          label: 'My Duties',
                          value: '$mine',
                          icon: Icons.assignment_ind,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _SummaryCard(
                          label: 'Pending\nApprovals',
                          value: '$pending',
                          icon: Icons.pending_actions,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _SummaryCard(
                          label: 'Completed',
                          value: '$completed',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ],
                    );
                  }),
                ),

                // Completion requests
                Obx(() {
                  final requests = taskCtrl.completionRequests;
                  if (requests.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Awaiting Verification',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ...requests.map((req) => _CompletionRequestCard(
                            completion: req,
                            taskCtrl: taskCtrl,
                            authCtrl: authCtrl,
                          )),
                    ],
                  );
                }),

                // Upcoming duties
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.upcoming, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Duties',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.toNamed(Routes.TASKS),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),

                Obx(() {
                  final rotations = taskCtrl.upcomingRotations;
                  final tasks = taskCtrl.tasks;
                  final members = taskCtrl.members;
                  if (rotations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyStateWidget(
                        icon: Icons.task_alt,
                        title: 'No upcoming duties',
                        subtitle: 'Generate rotations from the Tasks screen.',
                        actionLabel: 'Go to Tasks',
                        onAction: () => Get.toNamed(Routes.TASKS),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rotations.length > 5 ? 5 : rotations.length,
                    itemBuilder: (ctx, i) {
                      final rotation = rotations[i];
                      final task = tasks.firstWhereOrNull((t) => t.taskId == rotation.taskId);
                      final member = members.firstWhereOrNull((m) => m.uid == rotation.assignedUserId);
                      final isMe = rotation.assignedUserId == authCtrl.currentUser.value?.uid;

                      return _DutyCard(
                        rotation: rotation,
                        task: task,
                        member: member,
                        isMe: isMe,
                        taskCtrl: taskCtrl,
                      );
                    },
                  );
                }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  final DutyRotationModel rotation;
  final TaskModel? task;
  final UserModel? member;
  final bool isMe;
  final TaskController taskCtrl;

  const _DutyCard({
    required this.rotation,
    required this.task,
    required this.member,
    required this.isMe,
    required this.taskCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final taskType = task?.taskType;
    final color = _taskColor(taskType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  taskType?.icon ?? '📋',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskType?.label ?? 'Task',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      AppAvatar(
                        photoUrl: member?.photoUrl,
                        name: member?.name ?? '?',
                        radius: 10,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMe ? 'You' : (member?.name ?? 'Unknown'),
                        style: TextStyle(
                          color: isMe ? color : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMe && rotation.status == RotationStatus.pending)
              ElevatedButton(
                onPressed: () => taskCtrl.submitCompletion(rotation),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  backgroundColor: color,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 12)),
              )
            else if (rotation.status == RotationStatus.inProgress)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verifying',
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _taskColor(TaskType? type) {
    switch (type) {
      case TaskType.teaMaking: return AppColors.teaMaking;
      case TaskType.bathroomCleaning: return AppColors.bathroomCleaning;
      case TaskType.basinCleaning: return AppColors.basinCleaning;
      case TaskType.waterFilterRefill: return AppColors.waterFilter;
      case TaskType.garbageDisposal: return AppColors.garbageDisposal;
      default: return AppColors.primary;
    }
  }
}

class _CompletionRequestCard extends StatelessWidget {
  final TaskCompletionModel completion;
  final TaskController taskCtrl;
  final AuthController authCtrl;

  const _CompletionRequestCard({
    required this.completion,
    required this.taskCtrl,
    required this.authCtrl,
  });

  static Color _taskColor(TaskType? type) {
    switch (type) {
      case TaskType.teaMaking: return AppColors.teaMaking;
      case TaskType.bathroomCleaning: return AppColors.bathroomCleaning;
      case TaskType.basinCleaning: return AppColors.basinCleaning;
      case TaskType.waterFilterRefill: return AppColors.waterFilter;
      case TaskType.garbageDisposal: return AppColors.garbageDisposal;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = authCtrl.currentUser.value?.uid;
    final isRequester = completion.requestedBy == currentUid;
    final hasAccepted = completion.acceptedBy.contains(currentUid);
    final accepted = completion.acceptedBy.length;
    final requiredCount = completion.requiredAcceptances;
    final progress = (accepted / requiredCount).clamp(0.0, 1.0);

    final task = taskCtrl.tasks.firstWhereOrNull((t) => t.taskId == completion.taskId);
    final requester = taskCtrl.members.firstWhereOrNull((m) => m.uid == completion.requestedBy);
    final taskType = task?.taskType;
    final color = _taskColor(taskType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Task icon + name + verification count ──────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(taskType?.icon ?? '📋', style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskType?.label ?? 'Unknown Task',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Completion Verification',
                        style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (progress >= 1 ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$accepted / $requiredCount ✓',
                    style: TextStyle(
                      color: progress >= 1 ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Row 2: Who submitted ───────────────────────────────────
            Row(
              children: [
                AppAvatar(photoUrl: requester?.photoUrl, name: requester?.name ?? '?', radius: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      children: [
                        TextSpan(
                          text: isRequester ? 'You' : (requester?.name ?? 'Someone'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const TextSpan(text: ' submitted a completion request'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Progress bar ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(progress >= 1 ? AppColors.success : AppColors.warning),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Needs $requiredCount member verifications to mark as done',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),

            // ── Action buttons ────────────────────────────────────────
            if (!isRequester && !hasAccepted) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => taskCtrl.rejectCompletion(completion),
                      icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                      label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => taskCtrl.acceptCompletion(completion),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isRequester) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.hourglass_top, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting for ${requiredCount - accepted} more verification${(requiredCount - accepted) != 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text('You verified this task',
                      style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}



