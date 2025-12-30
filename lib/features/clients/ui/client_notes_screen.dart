import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class ClientNotesScreen extends StatefulWidget {
  final String clientId;

  const ClientNotesScreen({super.key, required this.clientId});

  @override
  State<ClientNotesScreen> createState() => _ClientNotesScreenState();
}

class _ClientNotesScreenState extends State<ClientNotesScreen> {
  final _controller = TextEditingController();
  final _logController = TextEditingController();
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  bool _saving = false;
  bool _editing = false;
  String _query = '';
  String _lastSaved = '';

  DocumentReference<Map<String, dynamic>> get _ref {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User not authenticated');

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .doc(widget.clientId);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _ref.update({'notes': _controller.text.trim()});
    if (!mounted) return;
    _lastSaved = _controller.text.trim();
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notes saved')));
  }

  @override
  void dispose() {
    _controller.dispose();
    _logController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _logRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .collection('communications');
  }

  Future<void> _addLog(String uid) async {
    final text = _logController.text.trim();
    if (text.isEmpty) return;
    await _logRef(uid).add({
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _logController.clear();
  }

  void _resetNotes() {
    _controller.text = _lastSaved;
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  Future<void> _deleteLog(String uid, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete log entry?'),
        content: const Text('This will remove the note from the log.'),
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
    await _logRef(uid).doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Notes'),
        actions: [
          TextButton.icon(
            onPressed: _controller.text.trim() == _lastSaved ? null : _resetNotes,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Reset'),
          ),
          TextButton.icon(
            onPressed:
                _saving || _controller.text.trim() == _lastSaved ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading notes...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load notes.');
          }
          if (!_editing) {
            _controller.text = (snap.data?.data()?['notes'] ?? '').toString();
            _lastSaved = _controller.text.trim();
          }

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
                  Text('Private Notes', style: AppText.h2(context))
                      .animate()
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: .03, end: 0),

                  SizedBox(height: Responsive.gap(context, 1)),

                  Text(
                    'Only visible to you. Track habits, warnings, or expectations.',
                    style: AppText.bodyMuted(context),
                  ),

                  SizedBox(height: Responsive.gap(context, 2)),

                  _NotesCard(
                    controller: _controller,
                    showClear: _controller.text.isNotEmpty,
                    onChanged: (_) => setState(() {}),
                    onFocus: () => setState(() => _editing = true),
                    onBlur: () => setState(() => _editing = false),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: .03, end: 0),

                  SizedBox(height: Responsive.gap(context, 2)),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ||
                              _controller.text.trim() == _lastSaved
                          ? null
                          : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save Notes'),
                    ),
                  ),

                  SizedBox(height: Responsive.gap(context, 2)),

                  Text('Communication log', style: AppText.h3(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Keep a running log of client conversations.',
                    style: AppText.bodyMuted(context),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _logController,
                          label: 'Add note',
                          icon: Icons.chat_bubble_outline_rounded,
                          textInputAction: TextInputAction.done,
                          showClear: _logController.text.isNotEmpty,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _addLog(uid),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Add',
                        onPressed: () => _addLog(uid),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _queryController,
                    label: 'Search log',
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
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _logRef(uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, logSnap) {
                      if (logSnap.connectionState == ConnectionState.waiting) {
                        return const LoadingState(message: 'Loading log...');
                      }
                      final logs = logSnap.data?.docs ?? const [];
                      final filtered = logs.where((doc) {
                        if (_query.isEmpty) return true;
                        final message =
                            (doc.data()['message'] ?? '').toString().toLowerCase();
                        return message.contains(_query.toLowerCase());
                      }).toList();
                      if (logs.isEmpty) {
                        return const EmptyState(
                          icon: Icons.forum_rounded,
                          title: 'No notes yet',
                          message:
                              'Add a message to start building the timeline.',
                        );
                      }
                      if (filtered.isEmpty) {
                        return const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching notes',
                          message: 'Try a different search term.',
                        );
                      }
                      return Column(
                        children: filtered.map((doc) {
                          final data = doc.data();
                          final message = (data['message'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  color: AppColors.subtext,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: AppText.body(context),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteLog(uid, doc.id),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
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

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String>? onChanged;
  final VoidCallback onFocus;
  final VoidCallback onBlur;

  const _NotesCard({
    required this.controller,
    required this.showClear,
    this.onChanged,
    required this.onFocus,
    required this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Focus(
        onFocusChange: (focus) => focus ? onFocus() : onBlur(),
        child: AppTextField(
          controller: controller,
          label: 'Internal notes',
          hint: 'Client habits, expectations, warnings...',
          maxLines: 8,
          showClear: showClear,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
