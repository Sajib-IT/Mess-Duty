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
                    label: Text(f['label']!),
                    selected: histCtrl.filter.value == f['value'],
                    onSelected: (_) => histCtrl.filter.value = f['value']!,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        )),
        Expanded(
          child: Obx(() {
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
            child: Text(task?.taskType.icon ?? '📋', style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(task?.taskType.label ?? 'Task',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            AppAvatar(photoUrl: member?.photoUrl, name: member?.name ?? '?', radius: 10),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                member?.name ?? 'Unknown',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '• ${AppHelpers.formatShortDate(rotation.scheduledDate)}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 24),
            Text('Completion Rate',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: histCtrl.completionRate,
                          color: AppColors.success,
                          title: '${histCtrl.completionRate.toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: 100 - histCtrl.completionRate,
                          color: Colors.grey.shade200,
                          title: '',
                          radius: 50,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(color: AppColors.success, label: 'Completed (${histCtrl.completedCount})'),
                    _LegendItem(color: AppColors.warning, label: 'Skipped (${histCtrl.skippedCount})'),
                    _LegendItem(color: Colors.grey, label: 'Pending (${histCtrl.pendingCount})'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final HistoryController histCtrl;
  final TaskController taskCtrl;
  const _StatsTab({required this.histCtrl, required this.taskCtrl});

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
          ...members.map((m) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: AppAvatar(photoUrl: m.photoUrl, name: m.name, radius: 22),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${m.daysInMess} days in mess'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${m.totalDutiesDone}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Text('duties done', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          )),
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



