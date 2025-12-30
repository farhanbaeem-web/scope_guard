import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../clients/data/client_model.dart';
import '../../clients/logic/clients_service.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _costOnly = false;
  bool _showOutOfScope = true;

  Stream<_AlertSummary> _stream() async* {
    await for (final clients in ClientsService.instance.watchClients()) {
      if (clients.isEmpty) {
        yield const _AlertSummary(clients: [], requests: []);
        continue;
      }
      final streams =
          clients.map((c) => RequestsService.instance.watchRequests(c.id));
      yield* StreamZip(streams).map((groups) {
        final merged = <_AlertItem>[];
        for (int i = 0; i < groups.length; i++) {
          final clientId = clients[i].id;
          for (final request in groups[i]) {
            merged.add(_AlertItem(clientId: clientId, request: request));
          }
        }
        return _AlertSummary(clients: clients, requests: merged);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Risks')),
      body: StreamBuilder<_AlertSummary>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading alerts...');
          }
          final summary = snap.data;
          if (summary == null) {
            return const EmptyState(
              icon: Icons.warning_rounded,
              title: 'No alerts yet',
              message: 'Alerts will appear as scope shifts happen.',
            );
          }

          final riskyClients =
              summary.clients.where((c) => c.risky).toList();
          final outOfScope = summary.requests
              .where((r) => !r.request.inScope)
              .toList();
          final filteredOut = outOfScope.where((r) {
            if (_costOnly && (r.request.estimatedCost ?? 0) <= 0) return false;
            return true;
          }).toList()
            ..sort(
              (a, b) =>
                  (b.request.estimatedCost ?? 0)
                      .compareTo(a.request.estimatedCost ?? 0),
            );
          final clientMap = {
            for (final c in summary.clients) c.id: c.name,
          };
          final totalExtra = outOfScope.fold<int>(
            0,
            (sum, r) => sum + (r.request.estimatedCost ?? 0),
          );

          return Responsive.centeredContent(
            context,
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: Scrollbar(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: Responsive.bottomSafeSpace(context, extra: 24),
                    top: 12,
                  ),
                  children: [
                    Text('At-risk overview', style: AppText.h2(context)),
                    const SizedBox(height: 12),
                    _MetricRow(
                      label: 'Risky clients',
                      value: '${riskyClients.length}',
                    ),
                    _MetricRow(
                      label: 'Out-of-scope requests',
                      value: '${outOfScope.length}',
                    ),
                    _MetricRow(
                      label: 'Potential extra revenue',
                      value: Formatters.currency(totalExtra),
                    ),
                    const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Out-of-scope list'),
                        selected: _showOutOfScope,
                        onSelected: (v) =>
                            setState(() => _showOutOfScope = v),
                      ),
                      FilterChip(
                        label: const Text('Only with cost'),
                        selected: _costOnly,
                        onSelected: (v) =>
                            setState(() => _costOnly = v),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/requests'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Open Requests Hub'),
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),
                    Text('Risky clients', style: AppText.h3(context)),
                    const SizedBox(height: 8),
                    if (riskyClients.isEmpty)
                      const EmptyState(
                        icon: Icons.people_alt_rounded,
                        title: 'No risky clients',
                        message: 'All clients look healthy.',
                      )
                    else
                      ...riskyClients.map(
                        (c) => ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.project),
                          trailing: const Icon(Icons.warning_rounded),
                        ),
                      ),
                    if (_showOutOfScope) ...[
                      const SizedBox(height: 16),
                      Text('Out-of-scope requests', style: AppText.h3(context)),
                      const SizedBox(height: 8),
                      if (filteredOut.isEmpty)
                        const EmptyState(
                          icon: Icons.assignment_late_rounded,
                          title: 'No out-of-scope requests',
                          message: 'Your scope looks clean right now.',
                        )
                      else
                        ...filteredOut.take(6).map(
                          (r) => ListTile(
                            title: Text(r.request.title),
                            subtitle: Text(
                              clientMap[r.clientId] ?? 'Client',
                            ),
                            trailing: Text(
                              Formatters.currency(
                                r.request.estimatedCost ?? 0,
                              ),
                              style: AppText.title(context),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(context))),
          Text(value, style: AppText.title(context)),
        ],
      ),
    );
  }
}

class _AlertSummary {
  final List<ClientModel> clients;
  final List<_AlertItem> requests;

  const _AlertSummary({required this.clients, required this.requests});
}

class _AlertItem {
  final String clientId;
  final RequestModel request;

  const _AlertItem({required this.clientId, required this.request});
}
