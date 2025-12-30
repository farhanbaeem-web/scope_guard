import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactor = false;
  bool _deviceAlerts = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('security');
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    await _ref(uid).set(
      {
        'twoFactor': _twoFactor,
        'deviceAlerts': _deviceAlerts,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security settings saved')),
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
        title: const Text('Security'),
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
            return const LoadingState(message: 'Loading security...');
          }
          final data = snap.data?.data() ?? {};
          _twoFactor = (data['twoFactor'] as bool?) ?? _twoFactor;
          _deviceAlerts = (data['deviceAlerts'] as bool?) ?? _deviceAlerts;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Security controls', style: AppText.h2(context)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                  title: const Text('Two-factor authentication'),
                  subtitle: const Text('Require a second factor on login'),
                ),
                SwitchListTile(
                  value: _deviceAlerts,
                  onChanged: (v) => setState(() => _deviceAlerts = v),
                  title: const Text('New device alerts'),
                  subtitle: const Text('Email when a new device signs in'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
