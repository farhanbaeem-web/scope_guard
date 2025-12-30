import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class DataRetentionScreen extends StatefulWidget {
  const DataRetentionScreen({super.key});

  @override
  State<DataRetentionScreen> createState() => _DataRetentionScreenState();
}

class _DataRetentionScreenState extends State<DataRetentionScreen> {
  final _retention = TextEditingController();
  final _exportsEmail = TextEditingController();
  bool _autoExport = false;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('data');
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    await _ref(uid).set(
      {
        'retentionDays': _retention.text.trim(),
        'exportsEmail': _exportsEmail.text.trim(),
        'autoExport': _autoExport,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data settings saved')),
    );
  }

  @override
  void dispose() {
    _retention.dispose();
    _exportsEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export & Retention'),
        actions: [
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
            return const LoadingState(message: 'Loading data settings...');
          }
          final data = snap.data?.data() ?? {};
          _retention.text = (data['retentionDays'] ?? '').toString();
          _exportsEmail.text = (data['exportsEmail'] ?? '').toString();
          _autoExport = (data['autoExport'] as bool?) ?? _autoExport;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Retention policy', style: AppText.h2(context)),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _retention,
                  label: 'Retention days',
                  icon: Icons.event_busy_rounded,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _exportsEmail,
                  label: 'Exports email',
                  icon: Icons.email_rounded,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _autoExport,
                  onChanged: (v) => setState(() => _autoExport = v),
                  title: const Text('Auto-export weekly'),
                  subtitle: const Text('Send exports to email every Friday'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
