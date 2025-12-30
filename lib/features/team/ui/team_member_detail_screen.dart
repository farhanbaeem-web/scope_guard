import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class TeamMemberDetailScreen extends StatelessWidget {
  final String memberId;

  const TeamMemberDetailScreen({
    super.key,
    required this.memberId,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('team')
        .doc(memberId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Member')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading member...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load member.');
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const EmptyState(
              icon: Icons.person_rounded,
              title: 'Member not found',
              message: 'This teammate may have been removed.',
            );
          }
          final data = snap.data!.data() ?? {};
          final name = (data['name'] ?? 'Member').toString();
          final email = (data['email'] ?? '').toString();
          final role = (data['role'] ?? 'Collaborator').toString();
          final status = (data['status'] ?? 'active').toString();

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text(name, style: AppText.h2(context)),
                const SizedBox(height: 8),
                if (email.isNotEmpty)
                  Text(email, style: AppText.bodyMuted(context)),
                const SizedBox(height: 12),
                _Row(label: 'Role', value: role),
                _Row(label: 'Status', value: status),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('Manage permissions'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(context))),
          Text(value, style: AppText.title(context)),
        ],
      ),
    );
  }
}
