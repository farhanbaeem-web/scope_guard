import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../data/request_model.dart';
import '../logic/requests_service.dart';

class RequestAddEditScreen extends StatefulWidget {
  final String clientId;
  final String? requestId;

  const RequestAddEditScreen({
    super.key,
    required this.clientId,
    this.requestId,
  });

  @override
  State<RequestAddEditScreen> createState() => _RequestAddEditScreenState();
}

class _RequestAddEditScreenState extends State<RequestAddEditScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  bool _inScope = true;
  bool _saving = false;

  bool get _isEdit => widget.requestId != null;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .collection('requests')
        .doc(widget.requestId);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await RequestsService.instance.updateRequest(
          clientId: widget.clientId,
          requestId: widget.requestId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          inScope: _inScope,
          estimatedCost:
              _inScope ? null : int.tryParse(_cost.text.trim()),
        );
      } else {
        await RequestsService.instance.addRequest(
          clientId: widget.clientId,
          title: _title.text.trim(),
          description: _description.text.trim(),
          inScope: _inScope,
          estimatedCost:
              _inScope ? null : int.tryParse(_cost.text.trim()),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _apply(RequestModel request) {
    _title.text = request.title;
    _description.text = request.description;
    _inScope = request.inScope;
    _cost.text = request.estimatedCost?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Request' : 'Add Request'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
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
      body: _isEdit
          ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _doc(uid).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState(message: 'Loading request...');
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const ErrorState(message: 'Request not found.');
                }
                _apply(RequestModel.fromDoc(snap.data!));
                return _form(context);
              },
            )
          : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    return Responsive.centeredContent(
      context,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: Responsive.bottomSafeSpace(context, extra: 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Update request' : 'New request',
                style: AppText.h2(context)),
            const SizedBox(height: 12),
            AppTextField(
              controller: _title,
              label: 'Title',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _description,
              label: 'Description',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _inScope,
              onChanged: (v) => setState(() => _inScope = v),
              title: Text(_inScope ? 'In scope' : 'Out of scope'),
              subtitle: Text(
                _inScope
                    ? 'Within original agreement'
                    : 'Will be billed as extra',
                style: AppText.subtitle(context),
              ),
            ),
            if (!_inScope)
              AppTextField(
                controller: _cost,
                label: 'Estimated cost',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
