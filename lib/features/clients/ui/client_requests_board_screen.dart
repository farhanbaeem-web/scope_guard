import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';
import '../../requests/ui/widgets/request_tile.dart';

class ClientRequestsBoardScreen extends StatelessWidget {
  final String clientId;
  final String clientName;

  const ClientRequestsBoardScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests Board')),
      body: StreamBuilder<List<RequestModel>>(
        stream: RequestsService.instance.watchRequests(clientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading requests...');
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.view_kanban_rounded,
              title: 'No requests yet',
              message: 'Add requests to see them organized by status.',
            );
          }

          final inScope = items.where((r) => r.inScope).toList();
          final pending = items
              .where((r) => r.approvalStatus == 'pending')
              .toList();
          final outOfScope = items
              .where((r) => !r.inScope && r.approvalStatus != 'pending')
              .toList();

          final gap = Responsive.gap(context, 1);
          final isDesktop = Responsive.isDesktop(context);

          final columns = [
            _BoardColumn(title: 'In scope', items: inScope),
            _BoardColumn(
              title: 'Needs approval',
              items: pending,
              accent: AppColors.warning,
            ),
            _BoardColumn(
              title: 'Out of scope',
              items: outOfScope,
              accent: AppColors.danger,
            ),
          ];

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: Responsive.bottomSafeSpace(context, extra: 24),
              top: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName, style: AppText.h2(context)),
                const SizedBox(height: 8),
                Text(
                  'Drag-style overview of requests and approvals.',
                  style: AppText.bodyMuted(context),
                ),
                SizedBox(height: gap),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < columns.length; i++) ...[
                            Expanded(child: columns[i]),
                            if (i != columns.length - 1)
                              SizedBox(width: gap),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          for (final column in columns) ...[
                            column,
                            SizedBox(height: gap),
                          ],
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final String title;
  final List<RequestModel> items;
  final Color? accent;

  const _BoardColumn({
    required this.title,
    required this.items,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppText.title(context)),
              const Spacer(),
              Text('${items.length}', style: AppText.small(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.inbox_rounded,
              title: 'No items',
              message: 'This column is empty for now.',
            )
          else
            ...items.map((r) => RequestTile(request: r)).toList(),
        ],
      ),
    );
  }
}
