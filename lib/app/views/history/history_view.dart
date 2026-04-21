import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/task_models.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/shared_widgets.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final histCtrl = Get.find<HistoryController>();
    final taskCtrl = Get.find<TaskController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History & Stats'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Timeline'),
              Tab(text: 'Charts'),
              Tab(text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TimelineTab(histCtrl: histCtrl, taskCtrl: taskCtrl),
            _ChartsTab(histCtrl: histCtrl, taskCtrl: taskCtrl),
            _StatsTab(histCtrl: histCtrl, taskCtrl: taskCtrl),
          ],
        ),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final HistoryController histCtrl;
  final TaskController taskCtrl;
  const _TimelineTab({required this.histCtrl, required this.taskCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              for (final f in [
                {'value': 'all', 'label': 'All'},
                {'value': 'mine', 'label': 'Mine'},
                {'value': 'week', 'label': 'This Week'},
                {'value': 'month', 'label': 'This Month'},
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!,style: TextStyle(color: AppColors.primary),),
                    selected: histCtrl.filter.value == f['value'],
                    onSelected: (_) => histCtrl.filter.value = f['value']!,
                    selectedColor: AppColors.primary.withValues(alpha: 0.28),
                    checkmarkColor: AppColors.primary,
                    selectedShadowColor: Colors.black,
                  ),
                ),
            ],
          ),
        )),
        Expanded(
          child: Obx(() {
            if (histCtrl.isRefreshing.value) {
              return ShimmerList(count: 6, tileBuilder: () => const ShimmerListTile());
            }
            final history = histCtrl.filteredHistory;
            if (history.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.history,
                title: 'No history yet',
                subtitle: 'Completed duties will appear here.',
              );
            }
            return ListView.builder(
              itemCount: history.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) {
                final r = history[i];
                final task = taskCtrl.tasks.firstWhereOrNull((t) => t.taskId == r.taskId);
                final member = taskCtrl.members.firstWhereOrNull((m) => m.uid == r.assignedUserId);
                return _HistoryTile(rotation: r, task: task, member: member);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DutyRotationModel rotation;
  final TaskModel? task;
  final UserModel? member;

  const _HistoryTile({required this.rotation, this.task, this.member});

  Color get _statusColor {
    switch (rotation.status) {
      case RotationStatus.completed: return AppColors.success;
      case RotationStatus.skipped: return AppColors.warning;
      case RotationStatus.inProgress: return AppColors.info;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(task?.displayIcon ?? '📋', style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(task?.displayLabel ?? 'Task',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            AppAvatar(photoUrl: member?.photoUrl, name: member?.name ?? '?', radius: 10),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member?.name ?? 'Unknown',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppHelpers.formatDateTime(rotation.scheduledDate),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rotation.status.value.capitalizeFirst ?? '',
            style: TextStyle(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  final HistoryController histCtrl;
  final TaskController taskCtrl;
  const _ChartsTab({required this.histCtrl, required this.taskCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = histCtrl.dutiesPerMember;
      if (data.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.bar_chart,
          title: 'No chart data',
          subtitle: 'Complete some duties to see charts.',
        );
      }

      final members = taskCtrl.members;
      final entries = data.entries.toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bar chart: duties per member ──────────────────────────
            Text('Duties per Member',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (data.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  barGroups: List.generate(entries.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          color: AppColors.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= entries.length) return const SizedBox();
                          final member = members.firstWhereOrNull((m) => m.uid == entries[idx].key);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              (member?.name ?? '?').split(' ').first,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, m) =>
                            Text(v.toInt().toString(), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Per-member completion rate pie charts ─────────────────
            Text('Completion Rate by Member',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Completed · Skipped · Pending breakdown per person',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            ...members.map((m) {
              final stats = histCtrl.completionRatePerMember[m.uid] ??
                  {'completed': 0, 'skipped': 0, 'pending': 0};
              final completed = stats['completed']!;
              final skipped   = stats['skipped']!;
              final pending   = stats['pending']!;
              final total     = completed + skipped + pending;

              final compPct   = total == 0 ? 0 : (completed / total * 100).round();

              final sections = <PieChartSectionData>[
                if (completed > 0)
                  PieChartSectionData(
                    value: completed.toDouble(),
                    color: AppColors.success,
                    title: '$compPct%',
                    radius: 52,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                if (skipped > 0)
                  PieChartSectionData(
                    value: skipped.toDouble(),
                    color: AppColors.warning,
                    title: '${total == 0 ? 0 : (skipped / total * 100).round()}%',
                    radius: 52,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                if (pending > 0)
                  PieChartSectionData(
                    value: pending.toDouble(),
                    color: Colors.grey.shade300,
                    title: '${total == 0 ? 0 : (pending / total * 100).round()}%',
                    radius: 52,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
              ];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member header
                    Row(
                      children: [
                        AppAvatar(photoUrl: m.photoUrl, name: m.name, radius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        // Completion rate badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$compPct% done',
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (total == 0)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No duties assigned yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pie chart
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: PieChart(
                              PieChartData(
                                sections: sections,
                                sectionsSpace: 2,
                                centerSpaceRadius: 20,
                                centerSpaceColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Legend
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RateLegend(
                                color: AppColors.success,
                                label: 'Completed',
                                count: completed,
                                total: total,
                              ),
                              const SizedBox(height: 8),
                              _RateLegend(
                                color: AppColors.warning,
                                label: 'Skipped',
                                count: skipped,
                                total: total,
                              ),
                              const SizedBox(height: 8),
                              _RateLegend(
                                color: Colors.grey.shade400,
                                label: 'Pending',
                                count: pending,
                                total: total,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Total: $total duties',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _RateLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _RateLegend({required this.color, required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12)),
        Text(
          '$count ($pct%)',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final HistoryController histCtrl;
  final TaskController taskCtrl;
  const _StatsTab({required this.histCtrl, required this.taskCtrl});

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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = taskCtrl.members;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Total Duties',
            value: '${histCtrl.history.length}',
            icon: Icons.assignment,
            color: AppColors.primary,
          ),
          _StatCard(
            title: 'Completed',
            value: '${histCtrl.completedCount}',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          _StatCard(
            title: 'Completion Rate',
            value: '${histCtrl.completionRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: AppColors.info,
          ),
          const SizedBox(height: 16),
          Text('Member Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...members.map((m) {
            final perTask = histCtrl.dutiesPerMemberPerTask[m.uid] ?? {};
            final totalDone = perTask.values.fold(0, (a, b) => a + b);
            final tasks = taskCtrl.tasks;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  leading: AppAvatar(photoUrl: m.photoUrl, name: m.name, radius: 22),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m.daysInMess} days in mess · $totalDone duties done'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalDone',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const Text('total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    if (perTask.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('No completed duties yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      )
                    else
                      ...tasks.map((t) {
                        final count = perTask[t.taskId] ?? 0;
                        final taskColor = _taskColor(t.taskType);

                        // % of this task out of member's own total duties
                        final memberPct = totalDone == 0 ? 0 : ((count / totalDone) * 100).round();

                        // % of this member's count out of ALL members' total for this specific task
                        final taskTotal = histCtrl.totalDutiesPerTask[t.taskId] ?? 0;
                        final taskPct = taskTotal == 0 ? 0 : ((count / taskTotal) * 100).round();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: taskColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(t.displayIcon, style: const TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Task label
                              Expanded(
                                child: Text(
                                  t.displayLabel,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Count chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: taskColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(fontSize: 12, color: taskColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Member %
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$memberPct%',
                                    style: TextStyle(fontSize: 12, color: taskColor, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'of mine',
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              // All-members % for this task
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$taskPct%',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'of $taskTotal',
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}



