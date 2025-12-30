import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class ClientContractScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientContractScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientContractScreen> createState() => _ClientContractScreenState();
}

class _ClientContractScreenState extends State<ClientContractScreen> {
  final _title = TextEditingController();
  final _rate = TextEditingController();
  final _terms = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _scrollController = ScrollController();
  bool _saving = false;
  bool _loaded = false;
  Map<String, dynamic>? _lastData;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .collection('contract')
        .doc('meta');
  }

  @override
  void dispose() {
    _title.dispose();
    _rate.dispose();
    _terms.dispose();
    _start.dispose();
    _end.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    await _ref(uid).set(
      {
        'title': _title.text.trim(),
        'rate': _rate.text.trim(),
        'terms': _terms.text.trim(),
        'startDate': _start.text.trim(),
        'endDate': _end.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contract saved')),
    );
  }

  void _applyData(Map<String, dynamic>? data) {
    final d = data ?? {};
    _title.text = (d['title'] ?? '').toString();
    _rate.text = (d['rate'] ?? '').toString();
    _terms.text = (d['terms'] ?? '').toString();
    _start.text = (d['startDate'] ?? '').toString();
    _end.text = (d['endDate'] ?? '').toString();
  }

  void _resetToSaved() {
    _applyData(_lastData);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract & Terms'),
        actions: [
          TextButton.icon(
            onPressed: _loaded ? _resetToSaved : null,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Reset'),
          ),
          TextButton.icon(
            onPressed: _saving ? null : () => _save(uid),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref(uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading contract...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load contract.');
          }
          final data = snap.data?.data();
          _lastData = data;
          if (!_loaded) {
            _applyData(data);
            _loaded = true;
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
                      Text(widget.clientName, style: AppText.h2(context)),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _title,
                        label: 'Contract title',
                        icon: Icons.description_rounded,
                        textInputAction: TextInputAction.next,
                        showClear: _title.text.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _rate,
                        label: 'Billing rate',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        showClear: _rate.text.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _start,
                              label: 'Start date',
                              icon: Icons.event_rounded,
                              textInputAction: TextInputAction.next,
                              showClear: _start.text.isNotEmpty,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _end,
                              label: 'End date',
                              icon: Icons.event_busy_rounded,
                              textInputAction: TextInputAction.next,
                              showClear: _end.text.isNotEmpty,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _terms,
                        label: 'Terms',
                        icon: Icons.notes_rounded,
                        maxLines: 5,
                        textInputAction: TextInputAction.done,
                        showClear: _terms.text.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (!_saving) {
                            _save(uid);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_lastData?['updatedAt'] is Timestamp)
                        Text(
                          'Last updated: ${Formatters.shortDate((_lastData!['updatedAt'] as Timestamp).toDate())}',
                          style: AppText.small(context),
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
