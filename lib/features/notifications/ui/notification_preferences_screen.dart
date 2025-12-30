import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _email = true;
  bool _push = true;
  bool _weekly = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('meta');
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    await _ref(uid).set(
      {
        'notifications': {
          'emailAlerts': _email,
          'pushAlerts': _push,
          'weeklySummary': _weekly,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: ErrorState(message: 'Not authenticated.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
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
            return const LoadingState(message: 'Loading preferences...');
          }
          final data = snap.data?.data() ?? {};
          final n = data['notifications'] as Map<String, dynamic>? ?? {};
          _email = (n['emailAlerts'] as bool?) ?? _email;
          _push = (n['pushAlerts'] as bool?) ?? _push;
          _weekly = (n['weeklySummary'] as bool?) ?? _weekly;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Alert channels', style: AppText.h2(context)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                  title: const Text('Email alerts'),
                  subtitle: const Text('Send alerts to your inbox'),
                ),
                SwitchListTile(
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                  title: const Text('Push notifications'),
                  subtitle: const Text('Deliver alerts to devices'),
                ),
                SwitchListTile(
                  value: _weekly,
                  onChanged: (v) => setState(() => _weekly = v),
                  title: const Text('Weekly summary'),
                  subtitle: const Text('Friday recap email'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
