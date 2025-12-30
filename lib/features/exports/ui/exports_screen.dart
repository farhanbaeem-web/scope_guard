import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class ExportsScreen extends StatefulWidget {
  const ExportsScreen({super.key});

  @override
  State<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends State<ExportsScreen> {
  final _dateFmt = DateFormat('MMM d | h:mm a');
  final _scrollController = ScrollController();
  final _queryController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void dispose() {
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Stream<List<_Export>> _exports() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('exports')
        .orderBy('createdAt', descending: true);

    await for (final snap in col.snapshots()) {
      yield snap.docs.map(_Export.fromDoc).toList();
    }
  }

  Future<void> _startExport() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title = TextEditingController(text: 'Scope report');
    String format = 'PDF';
    bool includeCharts = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start an export', style: AppText.h3(context)),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: format,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  prefixIcon: Icon(Icons.layers_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                  DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                  DropdownMenuItem(value: 'XLSX', child: Text('Excel')),
                ],
                onChanged: (v) => format = v ?? format,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: includeCharts,
                onChanged: (v) => includeCharts = v,
                title: const Text('Include charts and insights'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (title.text.trim().isEmpty) return;
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('exports')
                        .add({
                      'title': title.text.trim(),
                      'format': format,
                      'status': 'processing',
                      'includeCharts': includeCharts,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    // Simulate a completion update so the stream reflects it in real time.
                    Future.delayed(const Duration(seconds: 2), () async {
                      await doc.update({
                        'status': 'ready',
                        'downloadUrl':
                            'https://example.com/exports/${doc.id}.${format.toLowerCase()}',
                      });
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Generate export'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _download(_Export export) async {
    if (export.downloadUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still processing, try again soon.')),
      );
      return;
    }
    final uri = Uri.parse(export.downloadUrl!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${export.downloadUrl}')),
      );
    }
  }

  Future<void> _remove(_Export export) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove export?'),
        content: const Text('This will delete the export record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('exports')
        .doc(export.id)
        .delete();
  }

  Future<void> _copyUrl(_Export export) async {
    if (export.downloadUrl == null) return;
    await Clipboard.setData(ClipboardData(text: export.downloadUrl!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_Export>>(
      stream: _exports(),
      builder: (context, snap) {
        final exports = snap.data ?? const [];
        final isLoading = snap.connectionState == ConnectionState.waiting;
        final filtered = exports.where((e) {
          if (_statusFilter != _StatusFilter.all &&
              e.status != _statusFilter.name) {
            return false;
          }
          if (_query.isEmpty) return true;
          return e.title.toLowerCase().contains(_query.toLowerCase());
        }).toList();

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
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              children: [
            Row(
              children: [
                Expanded(
                  child: Text('Exports', style: AppText.h2(context))
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: .02, end: 0),
                ),
                FilledButton.icon(
                  onPressed: _startExport,
                  icon: const Icon(Icons.file_upload_rounded),
                  label: const Text('New export'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (!isLoading && exports.isEmpty) _EmptyExports(onStart: _startExport),
            if (exports.isNotEmpty) ...[
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  labelText: 'Search exports',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _StatusFilter.values
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(filter.label),
                        selected: _statusFilter == filter,
                        onSelected: (_) =>
                            setState(() => _statusFilter = filter),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                const _EmptyFiltered()
              else
                ...filtered.asMap().entries.map(
                      (e) => _ExportTile(
                        export: e.value,
                        dateLabel: _dateFmt.format(e.value.createdAt),
                        onDownload: () => _download(e.value),
                        onRemove: () => _remove(e.value),
                        onCopy: () => _copyUrl(e.value),
                      )
                          .animate(delay: (30 * e.key).ms)
                          .fadeIn()
                          .slideY(begin: .02, end: 0),
                    ),
            ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExportTile extends StatelessWidget {
  final _Export export;
  final String dateLabel;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final VoidCallback onCopy;

  const _ExportTile({
    required this.export,
    required this.dateLabel,
    required this.onDownload,
    required this.onRemove,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final color = export.status == 'ready'
        ? AppColors.success
        : (export.status == 'processing' ? AppColors.warning : AppColors.subtext);
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              export.format == 'CSV'
                  ? Icons.grid_on_rounded
                  : (export.format == 'XLSX'
                      ? Icons.table_chart_rounded
                      : Icons.picture_as_pdf_rounded),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(export.title, style: AppText.title(context))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        export.status,
                        style: AppText.small(context).copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: ${export.format} | Charts: ${export.includeCharts ? 'yes' : 'no'}',
                  style: AppText.bodyMuted(context),
                ),
                const SizedBox(height: 4),
                Text('Requested $dateLabel', style: AppText.small(context)),
              ],
            ),
          ),
          Column(
            children: [
              TextButton(
                onPressed: export.downloadUrl == null ? null : onDownload,
                child: const Text('Download'),
              ),
              IconButton(
                tooltip: 'Copy link',
                onPressed: export.downloadUrl == null ? null : onCopy,
                icon: const Icon(Icons.link_rounded),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Export {
  final String id;
  final String title;
  final String format;
  final String status;
  final bool includeCharts;
  final String? downloadUrl;
  final DateTime createdAt;

  const _Export({
    required this.id,
    required this.title,
    required this.format,
    required this.status,
    required this.includeCharts,
    required this.downloadUrl,
    required this.createdAt,
  });

  factory _Export.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _Export(
      id: doc.id,
      title: (data['title'] ?? 'Export').toString(),
      format: (data['format'] ?? 'PDF').toString(),
      status: (data['status'] ?? 'ready').toString(),
      includeCharts: data['includeCharts'] == true,
      downloadUrl: data['downloadUrl']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class _EmptyExports extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyExports({required this.onStart});

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
          const Icon(Icons.file_upload_rounded, size: 40, color: AppColors.subtext),
          const SizedBox(height: 8),
          Text('No exports yet', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Create your first PDF, CSV, or Excel export to see it here.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.add),
            label: const Text('Start an export'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered();

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
          Text('No matching exports', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Try a different search or filter.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum _StatusFilter {
  all,
  ready,
  processing,
}

extension _StatusFilterLabel on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All';
      case _StatusFilter.ready:
        return 'Ready';
      case _StatusFilter.processing:
        return 'Processing';
    }
  }
}
