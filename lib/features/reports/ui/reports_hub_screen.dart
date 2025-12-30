import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../clients/data/client_model.dart';
import '../../clients/logic/clients_service.dart';

/// Report landing page that highlights PDF generation and deep-links into
/// client detail screens.
class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  late final ScrollController _scrollController;
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClientModel>>(
      stream: ClientsService.instance.watchClients(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading reports...');
        }
        if (snap.hasError) {
          return const ErrorState(
            message: 'Unable to load reports right now.',
          );
        }

        final clients = snap.data ?? const [];
        final filtered = clients.where((c) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.project.toLowerCase().contains(q);
        }).toList();
        if (clients.isEmpty) {
          return EmptyState(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Create a client first',
            message: 'Add a client, log a few requests, then export a PDF.',
            action: ElevatedButton.icon(
              onPressed: () => context.push('/clients/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add client'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Reports', style: AppText.h2(context)),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/analytics'),
                      icon: const Icon(Icons.auto_graph_rounded),
                      label: const Text('View analytics'),
                    ),
                  ],
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
                SizedBox(height: Responsive.gap(context, 1)),
                Text(
                  'Generate polished scope PDFs per client. Pick a client to open their detail view and export.',
                  style: AppText.subtitle(context),
                ).animate().fadeIn(delay: 80.ms).slideY(begin: .03, end: 0),
                SizedBox(height: Responsive.gap(context, 2)),
                AppTextField(
                  controller: _queryController,
                  label: 'Search clients',
                  icon: Icons.search_rounded,
                  showClear: _query.isNotEmpty,
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_query.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _query = '';
                          _queryController.clear();
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Clear search'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching clients',
                    message: 'Try a different search term.',
                  )
                else
                  Wrap(
                    spacing: Responsive.gap(context, 1),
                    runSpacing: Responsive.gap(context, 1),
                    children: filtered
                        .map(
                          (c) => _ReportCard(client: c)
                              .animate(delay: 60.ms)
                              .fadeIn()
                              .slideY(begin: .02, end: 0),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ClientModel client;
  const _ReportCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final radius = Responsive.radius(context);
    return Container(
      width: 340,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  client.name,
                  style: AppText.title(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            client.project,
            style: AppText.bodyMuted(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/clients/${client.id}', extra: client),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open client'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/clients/${client.id}', extra: client),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Generate report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
