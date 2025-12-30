import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _dateFmt = DateFormat('MMM d | h:mm a');
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<_Member>> _members() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('team')
        .orderBy('createdAt', descending: true);

    await for (final snap in col.snapshots()) {
      yield snap.docs.map(_Member.fromDoc).toList();
    }
  }

  Future<void> _inviteMember() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final name = TextEditingController();
    final email = TextEditingController();
    String role = 'Collaborator';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite teammate', style: AppText.h3(context)),
              const SizedBox(height: 10),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_add_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Work email',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.shield_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Collaborator', child: Text('Collaborator')),
                  DropdownMenuItem(value: 'Viewer', child: Text('Viewer')),
                ],
                onChanged: (v) => role = v ?? role,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (name.text.trim().isEmpty || email.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('team')
                        .add({
                      'name': name.text.trim(),
                      'email': email.text.trim(),
                      'role': role,
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send invite'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateRole(_Member member, String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('team')
        .doc(member.id)
        .update({'role': role, 'status': 'active'});
  }

  Future<void> _removeMember(_Member member) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('team')
        .doc(member.id)
        .delete();
  }

  Future<void> _seedSampleTeam() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('team');
    final batch = FirebaseFirestore.instance.batch();
    final now = FieldValue.serverTimestamp();
    for (final member in [
      {'name': 'Ava Chen', 'email': 'ava@scopeguard.io', 'role': 'Owner'},
      {'name': 'Luis Ortega', 'email': 'luis@scopeguard.io', 'role': 'Admin'},
      {'name': 'Mia Patel', 'email': 'mia@scopeguard.io', 'role': 'Collaborator'},
    ]) {
      batch.set(col.doc(), {
        ...member,
        'status': 'active',
        'createdAt': now,
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    return StreamBuilder<List<_Member>>(
      stream: _members(),
      builder: (context, snap) {
        final members = snap.data ?? const [];
        final isLoading = snap.connectionState == ConnectionState.waiting;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Team', style: AppText.h2(context))
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: .02, end: 0),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                    )
                  ],
                ),
                SizedBox(height: gap / 1.5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _inviteMember,
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Invite teammate'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _seedSampleTeam,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Seed sample data'),
                    ),
                  ],
                ),
                SizedBox(height: gap),
                if (isLoading) const Center(child: CircularProgressIndicator()),
                if (!isLoading && members.isEmpty) const _EmptyTeam(),
                if (members.isNotEmpty)
                  ...members.asMap().entries.map(
                        (e) => _MemberTile(
                          member: e.value,
                          dateLabel: _dateFmt.format(e.value.createdAt),
                          onPromote: () => _updateRole(e.value, 'Admin'),
                          onDemote: () => _updateRole(e.value, 'Collaborator'),
                          onRemove: () => _removeMember(e.value),
                          onOpen: () => context.push('/team/${e.value.id}'),
                        )
                            .animate(delay: (30 * e.key).ms)
                            .fadeIn()
                            .slideY(begin: .02, end: 0),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final _Member member;
  final String dateLabel;
  final VoidCallback onPromote;
  final VoidCallback onDemote;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _MemberTile({
    required this.member,
    required this.dateLabel,
    required this.onPromote,
    required this.onDemote,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = member.status == 'pending'
        ? AppColors.warning
        : (member.status == 'active' ? AppColors.success : AppColors.subtext);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(member.name, style: AppText.title(context))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.status,
                        style: AppText.small(context).copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(member.role, style: AppText.bodyMuted(context)),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(member.email, style: AppText.small(context)),
                ],
                const SizedBox(height: 4),
                Text('Joined $dateLabel', style: AppText.small(context)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'promote':
                  onPromote();
                  break;
                case 'demote':
                  onDemote();
                  break;
                case 'remove':
                  onRemove();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'promote', child: Text('Make admin')),
              PopupMenuItem(value: 'demote', child: Text('Set collaborator')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _Member {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  const _Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory _Member.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _Member(
      id: doc.id,
      name: (data['name'] ?? 'Member').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'Collaborator').toString(),
      status: (data['status'] ?? 'active').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_rounded, size: 40, color: AppColors.subtext),
          const SizedBox(height: 8),
          Text('No teammates yet', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Invite collaborators to share visibility and approvals.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
