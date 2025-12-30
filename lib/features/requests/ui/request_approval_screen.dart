import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class RequestApprovalScreen extends StatefulWidget {
  final String clientId;
  final String requestId;

  const RequestApprovalScreen({
    super.key,
    required this.clientId,
    required this.requestId,
  });

  @override
  State<RequestApprovalScreen> createState() => _RequestApprovalScreenState();
}

class _RequestApprovalScreenState extends State<RequestApprovalScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  String _status = 'pending';

  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .collection('requests')
        .doc(widget.requestId)
        .collection('approvals');
  }

  Future<void> _addApproval(String uid) async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await _ref(uid).add({
      'name': name,
      'note': _note.text.trim(),
      'status': _status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .collection('requests')
        .doc(widget.requestId)
        .update({'approvalStatus': _status});
    if (!mounted) return;
    _name.clear();
    _note.clear();
    setState(() => _status = 'pending');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Approval Workflow')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ref(uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading approvals...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load approvals.');
          }
          final items = snap.data?.docs ?? const [];

          return Responsive.centeredContent(
            context,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Approvals', style: AppText.h2(context)),
                  const SizedBox(height: 12),
                  _ApprovalForm(
                    name: _name,
                    note: _note,
                    status: _status,
                    onStatus: (v) => setState(() => _status = v),
                    onSubmit: () => _addApproval(uid),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const EmptyState(
                      icon: Icons.rule_rounded,
                      title: 'No approvals yet',
                      message: 'Log approvals as decisions are made.',
                    )
                  else
                    Column(
                      children: items.map((doc) {
                        final data = doc.data();
                        final status = (data['status'] ?? 'pending').toString();
                        final color = status == 'approved'
                            ? AppColors.success
                            : status == 'rejected'
                                ? AppColors.danger
                                : AppColors.warning;
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: AppText.chip(context)
                                      .copyWith(color: color),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (data['name'] ?? 'Approver').toString(),
                                      style: AppText.title(context),
                                    ),
                                    if ((data['note'] ?? '').toString().isNotEmpty)
                                      Text(
                                        (data['note'] ?? '').toString(),
                                        style: AppText.bodyMuted(context),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

class _ApprovalForm extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController note;
  final String status;
  final ValueChanged<String> onStatus;
  final VoidCallback onSubmit;

  const _ApprovalForm({
    required this.name,
    required this.note,
    required this.status,
    required this.onStatus,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Approver name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Note',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.rule_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            onChanged: (v) => onStatus(v ?? 'pending'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Log approval'),
            ),
          ),
        ],
      ),
    );
  }
}
