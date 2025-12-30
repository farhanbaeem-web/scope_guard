import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../data/activity_model.dart';
import '../logic/activity_service.dart';
import 'package:go_router/go_router.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityModel>>(
      stream: ActivityService.instance.watchActivity(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading activity...');
        }
        if (snap.hasError) {
          return ErrorState(
            message: 'Unable to load activity right now.',
            onRetry: () {},
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.timeline_rounded,
            title: 'No activity yet',
            message: 'Recent client and request events will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('Activity', style: AppText.h2(context)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.push('/activity/audit'),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('Audit log'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await _confirm(
                              context,
                              title: 'Clear activity log?',
                              message:
                                  'This will delete all activity entries.',
                            );
                            if (!ok) return;
                            await ActivityService.instance.clearAll();
                          },
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear all'),
                        ),
                      ],
                    ),
                  );
                }

                final item = items[i - 1];
                return _ActivityTile(
                  title: item.title,
                  detail: item.detail,
                  type: item.type,
                  timestamp: Formatters.relative(item.createdAt),
                  onDelete: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Delete activity item?',
                      message: 'This will remove the activity entry.',
                    );
                    if (!ok) return;
                    await ActivityService.instance.delete(item.id);
                  },
                ).animate(delay: (30 * i).ms).fadeIn().slideY(begin: .02, end: 0);
              },
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String detail;
  final ActivityType type;
  final String timestamp;
  final VoidCallback onDelete;

  const _ActivityTile({
    required this.title,
    required this.detail,
    required this.type,
    required this.timestamp,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ActivityType.danger => AppColors.danger,
      ActivityType.warning => AppColors.warning,
      ActivityType.success => AppColors.success,
      ActivityType.info => AppColors.info,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title(context)),
                const SizedBox(height: 4),
                Text(detail, style: AppText.bodyMuted(context)),
                const SizedBox(height: 4),
                Text(timestamp, style: AppText.small(context)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.subtext),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
