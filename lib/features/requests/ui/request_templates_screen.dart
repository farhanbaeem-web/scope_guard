import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/app_text_field.dart';

class RequestTemplatesScreen extends StatefulWidget {
  const RequestTemplatesScreen({super.key});

  @override
  State<RequestTemplatesScreen> createState() => _RequestTemplatesScreenState();
}

class _RequestTemplatesScreenState extends State<RequestTemplatesScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _canSave = false;

  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('requestTemplates');
  }

  @override
  void initState() {
    super.initState();
    _title.addListener(_syncCanSave);
  }

  void _syncCanSave() {
    final next = _title.text.trim().isNotEmpty;
    if (next != _canSave) {
      setState(() => _canSave = next);
    }
  }

  Future<void> _addTemplate(String uid) async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    await _ref(uid).add({
      'title': title,
      'description': _description.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _title.clear();
    _description.clear();
  }

  Future<void> _deleteTemplate(String uid, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: const Text('This will permanently remove the template.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _ref(uid).doc(id).delete();
  }

  void _clearForm() {
    _title.clear();
    _description.clear();
    _syncCanSave();
    FocusScope.of(context).unfocus();
  }

  void _loadTemplate(Map<String, dynamic> data) {
    _title.text = (data['title'] ?? '').toString();
    _description.text = (data['description'] ?? '').toString();
    _syncCanSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template loaded')),
    );
  }

  @override
  void dispose() {
    _title.removeListener(_syncCanSave);
    _title.dispose();
    _description.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Templates')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ref(uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading templates...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load templates.');
          }
          final items = snap.data?.docs ?? const [];
          final filtered = items.where((doc) {
            if (_query.isEmpty) return true;
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final desc = (data['description'] ?? '').toString().toLowerCase();
            final q = _query.toLowerCase();
            return title.contains(q) || desc.contains(q);
          }).toList();
          return Responsive.centeredContent(
            context,
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: Responsive.bottomSafeSpace(context, extra: 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Templates', style: AppText.h2(context)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _title,
                              label: 'Template title',
                              icon: Icons.title_rounded,
                              textInputAction: TextInputAction.next,
                              showClear: _title.text.isNotEmpty,
                              onChanged: (_) => _syncCanSave(),
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              controller: _description,
                              label: 'Description',
                              icon: Icons.notes_rounded,
                              textInputAction: TextInputAction.newline,
                              showClear: _description.text.isNotEmpty,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        _canSave ? () => _addTemplate(uid) : null,
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('Save template'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _title.text.isEmpty &&
                                          _description.text.isEmpty
                                      ? null
                                      : _clearForm,
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tip: tap a template below to load it into the form.',
                        style: AppText.small(context),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _queryController,
                        label: 'Search templates',
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
                          icon: Icons.article_rounded,
                          title: 'No templates yet',
                          message: 'Save templates to speed up request logging.',
                        )
                      else
                        Column(
                          children: filtered.map((doc) {
                            final data = doc.data();
                          return InkWell(
                            onTap: () => _loadTemplate(data),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.article_rounded,
                                      color: AppColors.subtext),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['title'] ?? 'Template')
                                              .toString(),
                                          style: AppText.title(context),
                                        ),
                                        if ((data['description'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            (data['description'] ?? '')
                                                .toString(),
                                            style: AppText.bodyMuted(context),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete template',
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                    onPressed: () =>
                                        _deleteTemplate(uid, doc.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
