import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../reports/data/report_model.dart';
import '../../reports/logic/reports_service.dart';

class ClientReportsScreen extends StatelessWidget {
  final String clientId;
  final String clientName;

  const ClientReportsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports Archive')),
      body: StreamBuilder<List<ReportModel>>(
        stream: ReportsService.instance.watchReports(clientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading reports...');
          }
          final reports = snap.data ?? const [];
          if (reports.isEmpty) {
            return EmptyState(
              icon: Icons.picture_as_pdf_rounded,
              title: 'No reports yet',
              message: 'Generate a report to start building history.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: Responsive.bottomSafeSpace(context, extra: 24),
              top: 12,
            ),
            itemCount: reports.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(clientName, style: AppText.h2(context)),
                );
              }
              final r = reports[i - 1];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: AppText.title(context)),
                          const SizedBox(height: 4),
                          Text(
                            '${r.outOfScopeCount} out of scope · '
                            '${Formatters.currency(r.totalExtra)}',
                            style: AppText.small(context),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.shortDate(r.createdAt),
                      style: AppText.small(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
