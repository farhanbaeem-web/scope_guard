import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final _scrollController = ScrollController();
  final _queryController = TextEditingController();
  String _query = '';
  bool _connectedOnly = false;
  _IntegrationSort _sort = _IntegrationSort.name;

  Stream<List<_Integration>> _stream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final colRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('integrations');
    final col = colRef.orderBy('name');

    await for (final snap in col.snapshots()) {
      if (snap.docs.isEmpty) {
        // Seed sensible defaults once for new users
        await colRef.add(_Integration.seed('Slack').toMap());
        await colRef.add(_Integration.seed('Notion').toMap());
        await colRef.add(_Integration.seed('Jira').toMap());
        await colRef.add(_Integration.seed('Zapier').toMap());
        continue;
      }
      yield snap.docs.map((d) => _Integration.fromDoc(d)).toList();
    }
  }

  Future<void> _toggle(String id, bool connected) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('integrations')
        .doc(id)
        .update({'connected': connected});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    return StreamBuilder<List<_Integration>>(
      stream: _stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        final filtered = items.where((i) {
          if (_connectedOnly && !i.connected) return false;
          if (_query.isEmpty) return true;
          return i.name.toLowerCase().contains(_query.toLowerCase());
        }).toList();
        filtered.sort((a, b) {
          switch (_sort) {
            case _IntegrationSort.name:
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case _IntegrationSort.connectedFirst:
              final c = (b.connected ? 1 : 0).compareTo(a.connected ? 1 : 0);
              if (c != 0) return c;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            Text('Integrations', style: AppText.h2(context)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Sync now'),
                      ),
                    ],
                  ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
                  SizedBox(height: gap),
                  Text(
                    'Connect Scope Guard to your daily stack for automated alerts, updates, and approvals.',
                    style: AppText.bodyMuted(context),
                  ).animate(delay: 60.ms).fadeIn().slideY(begin: .02, end: 0),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            labelText: 'Search integrations',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<_IntegrationSort>(
                          value: _sort,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _sort = value);
                          },
                          items: _IntegrationSort.values
                              .map(
                                (sort) => DropdownMenuItem(
                                  value: sort,
                                  child: Text(sort.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Connected only'),
                        selected: _connectedOnly,
                        onSelected: (value) =>
                            setState(() => _connectedOnly = value),
                      ),
                      if (_query.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _queryController.clear();
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Clear search'),
                        ),
                    ],
                  ),
                  SizedBox(height: gap),
                  if (filtered.isEmpty)
                    const _EmptyIntegrations()
                  else
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: filtered
                        .asMap()
                        .entries
                        .map(
                          (e) => _IntegrationCard(
                            integration: e.value,
                            onToggle: (v) => _toggle(e.value.id, v),
                            onOpen: () =>
                                context.push('/integrations/${e.value.id}'),
                          )
                              .animate(delay: (40 * e.key).ms)
                              .fadeIn()
                              .slideY(begin: .02, end: 0),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final _Integration integration;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpen;

  const _IntegrationCard({
    required this.integration,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final connected = integration.connected;
    return InkWell(
      onTap: onOpen,
      borderRadius: radius,
      child: Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 14,
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
                  color: integration.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(integration.icon, color: integration.color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(integration.name, style: AppText.title(context))),
              _StatusBadge(
                text: connected ? 'Connected' : 'Disconnected',
                color: connected ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(integration.description, style: AppText.bodyMuted(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onToggle(!connected),
                icon: Icon(connected ? Icons.check_circle_rounded : Icons.link_rounded),
                label: Text(connected ? 'Disconnect' : 'Connect'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('View logs'),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: AppText.chip(context).copyWith(color: color),
      ),
    );
  }
}

class _Integration {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool connected;

  const _Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.connected,
  });

  factory _Integration.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final iconKey = (data['iconName'] ?? data['name'] ?? 'integration').toString();
    return _Integration(
      id: doc.id,
      name: (data['name'] ?? 'Integration').toString(),
      description: (data['description'] ?? '').toString(),
      icon: _iconFor(iconKey),
      color: Color((data['color'] as int?) ?? AppColors.primary.value),
      connected: (data['connected'] as bool?) ?? false,
    );
  }

  static _Integration seed(String name) {
    switch (name) {
      case 'Slack':
        return _Integration(
          id: '',
          name: 'Slack',
          description: 'Send scope alerts to a channel and get approvals fast.',
          icon: Icons.message_rounded,
          color: const Color(0xFF4A8FE7),
          connected: false,
        );
      case 'Asana':
        return _Integration(
          id: '',
          name: 'Asana',
          description: 'Create tasks automatically when scope shifts.',
          icon: Icons.checklist_rounded,
          color: const Color(0xFF4A8FE7),
          connected: false,
        );
      case 'Notion':
        return _Integration(
          id: '',
          name: 'Notion',
          description: 'Sync client notes and decision logs automatically.',
          icon: Icons.book_outlined,
          color: const Color(0xFF171717),
          connected: false,
        );
      case 'Jira':
        return _Integration(
          id: '',
          name: 'Jira',
          description: 'Create tickets for out-of-scope requests in one tap.',
          icon: Icons.layers_rounded,
          color: const Color(0xFF0B74C4),
          connected: false,
        );
      default:
        return _Integration(
          id: '',
          name: 'Zapier',
          description: 'Trigger custom automations when requests change.',
          icon: Icons.flash_on_rounded,
          color: const Color(0xFFF59E0B),
          connected: false,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconName': name,
      'color': color.value,
      'connected': connected,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

IconData _iconFor(String key) {
  switch (key.toLowerCase()) {
    case 'slack':
      return Icons.message_rounded;
    case 'asana':
      return Icons.checklist_rounded;
    case 'notion':
      return Icons.book_outlined;
    case 'jira':
      return Icons.layers_rounded;
    case 'zapier':
      return Icons.flash_on_rounded;
    case 'salesforce':
      return Icons.business_center_rounded;
    case 'github':
      return Icons.code_rounded;
    case 'linear':
      return Icons.view_week_rounded;
    case 'monday':
      return Icons.calendar_view_week_rounded;
    default:
      return Icons.extension_rounded;
  }
}

class _EmptyIntegrations extends StatelessWidget {
  const _EmptyIntegrations();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 40, color: AppColors.subtext),
          const SizedBox(height: 8),
          Text('No matching integrations', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Try a different search term.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum _IntegrationSort { name, connectedFirst }

extension _IntegrationSortLabel on _IntegrationSort {
  String get label {
    switch (this) {
      case _IntegrationSort.name:
        return 'Name';
      case _IntegrationSort.connectedFirst:
        return 'Connected first';
    }
  }
}
