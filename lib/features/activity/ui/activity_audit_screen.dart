import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../data/activity_model.dart';
import '../logic/activity_service.dart';

class ActivityAuditScreen extends StatefulWidget {
  const ActivityAuditScreen({super.key});

  @override
  State<ActivityAuditScreen> createState() => _ActivityAuditScreenState();
}

class _ActivityAuditScreenState extends State<ActivityAuditScreen> {
  String _query = '';
  ActivityType? _filter;
  final _controller = TextEditingController();
  final _listController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: StreamBuilder<List<ActivityModel>>(
        stream: ActivityService.instance.watchActivity(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading audit log...');
          }
          final items = snap.data ?? const [];
          final filtered = items.where((a) {
            if (_filter != null && a.type != _filter) return false;
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return a.title.toLowerCase().contains(q) ||
                a.detail.toLowerCase().contains(q);
          }).toList();

          final height = MediaQuery.sizeOf(context).height -
              kToolbarHeight -
              MediaQuery.paddingOf(context).vertical;
          return Responsive.centeredContent(
            context,
            child: SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _controller,
                    label: 'Search activity',
                    icon: Icons.search_rounded,
                    showClear: _query.isNotEmpty,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final t in ActivityType.values)
                        _FilterChip(
                          label: t.name,
                          selected: _filter == t,
                          onTap: () => setState(() => _filter = t),
                        ),
                    ],
                  ),
                  if (_query.isNotEmpty || _filter != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _filter = null;
                            _controller.clear();
                          });
                        },
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.history_rounded,
                            title: 'No activity found',
                            message: 'Try adjusting filters or search.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: Scrollbar(
                              controller: _listController,
                              child: ListView.builder(
                                controller: _listController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final a = filtered[i];
                                  return ListTile(
                                    title: Text(a.title),
                                    subtitle: Text(a.detail),
                                    trailing: Text(
                                      Formatters.relative(a.createdAt),
                                      style: AppText.small(context),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
