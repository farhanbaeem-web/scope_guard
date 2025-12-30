import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class IntegrationDetailScreen extends StatelessWidget {
  final String integrationId;

  const IntegrationDetailScreen({
    super.key,
    required this.integrationId,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('integrations')
        .doc(integrationId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integration'),
        actions: [
          IconButton(
            tooltip: 'Copy integration ID',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: integrationId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Integration ID copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading integration...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load integration.');
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const EmptyState(
              icon: Icons.extension_rounded,
              title: 'Integration not found',
              message: 'This integration may have been removed.',
            );
          }
          final data = snap.data!.data() ?? {};
          final name = (data['name'] ?? 'Integration').toString();
          final description = (data['description'] ?? '').toString();
          final connected = (data['connected'] as bool?) ?? false;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text(name, style: AppText.h2(context)),
                const SizedBox(height: 8),
                Text(description, style: AppText.bodyMuted(context)),
                const SizedBox(height: 12),
                Text(
                  connected ? 'Status: Connected' : 'Status: Disconnected',
                  style: AppText.title(context),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Run sync'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
