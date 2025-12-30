import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _unreadOnly = false;

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.update({'read': true});
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _toggleRead(String id, bool read) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'read': read});
  }

  Future<void> _delete(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  Future<void> _clearAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyNotice();
        }

        final unread =
            docs.where((d) => (d.data()['read'] as bool?) != true).length;
        final filtered = _unreadOnly
            ? docs.where((d) => (d.data()['read'] as bool?) != true).toList()
            : docs;
        if (filtered.isEmpty) {
          return const _EmptyNotice(
            title: 'No unread notifications',
            message: 'You are all caught up.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('Notifications', style: AppText.h2(context)),
                        const SizedBox(width: 8),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$unread unread', style: AppText.chip(context)),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: unread == 0 ? null : () => _markAllRead(),
                          icon: const Icon(Icons.mark_email_read_rounded),
                          label: const Text('Mark all read'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/notifications/preferences'),
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Preferences'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear all notifications?'),
                                content: const Text(
                                  'This will delete all notifications.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            await _clearAll();
                          },
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear all'),
                        ),
                        const SizedBox(width: 4),
                        FilterChip(
                          label: const Text('Unread only'),
                          selected: _unreadOnly,
                          onSelected: (value) =>
                              setState(() => _unreadOnly = value),
                        ),
                      ],
                    ),
                  );
                }

                final doc = filtered[i - 1];
                final data = doc.data();
                final title = data['title']?.toString() ?? 'Notification';
                final body = data['body']?.toString() ?? '';
                final type = data['type']?.toString() ?? 'info';
                final created = data['createdAt'] as Timestamp?;
                final time = created == null
                    ? 'Just now'
                    : Formatters.relative(created.toDate());
                final color = type == 'warning'
                    ? AppColors.warning
                    : (type == 'danger' ? AppColors.danger : AppColors.info);
                final read = (data['read'] as bool?) ?? false;
                return _NotificationTile(
                  title: title,
                  body: body,
                  timestamp: time,
                  color: color,
                  read: read,
                  onToggleRead: () => _toggleRead(doc.id, !read),
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete notification?'),
                        content: const Text(
                          'This will remove the notification.',
                        ),
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
                    if (ok != true) return;
                    await _delete(doc.id);
                  },
                ).animate(delay: (30 * i).ms).fadeIn().slideY(begin: .02, end: 0);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: filtered.length + 1,
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String timestamp;
  final Color color;
  final bool read;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.color,
    required this.read,
    required this.onToggleRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: AppText.title(context))),
                    IconButton(
                      tooltip: read ? 'Mark unread' : 'Mark read',
                      icon: Icon(read ? Icons.mark_email_read : Icons.mark_email_unread,
                          color: read ? AppColors.subtext : AppColors.info),
                      onPressed: onToggleRead,
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.subtext),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: AppText.bodyMuted(context)),
                const SizedBox(height: 6),
                Text(timestamp, style: AppText.small(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyNotice({
    this.title = 'No notifications yet',
    this.message =
        'Alerts will appear here when clients or scope changes require attention.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_rounded,
                size: 42, color: AppColors.subtext),
            const SizedBox(height: 8),
            Text(title, style: AppText.title(context)),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppText.bodyMuted(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
