import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/app_text_field.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _message = TextEditingController();
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _sending = false;
  final _dateFmt = DateFormat('MMM d | h:mm a');

  @override
  void dispose() {
    _message.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<_Ticket>> _stream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('supportTickets')
        .orderBy('createdAt', descending: true);
    await for (final snap in col.snapshots()) {
      yield snap.docs.map(_Ticket.fromDoc).toList();
    }
  }

  Future<void> _submitTicket() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('supportTickets')
          .add({
        'message': _message.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(_Ticket ticket, String status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('supportTickets')
        .doc(ticket.id)
        .update({'status': status});
  }

  Future<void> _deleteTicket(_Ticket ticket) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ticket?'),
        content: const Text('This will remove the support ticket.'),
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
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('supportTickets')
        .doc(ticket.id)
        .delete();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    final whatsappUri = Uri.parse('https://wa.me/923150809665');
    final emailUri = Uri.parse('mailto:farhannaeem@gmail.com');
    return StreamBuilder<List<_Ticket>>(
      stream: _stream(),
      builder: (context, snap) {
        final tickets = snap.data ?? const [];
        final filtered = tickets.where((t) {
          if (_query.isEmpty) return true;
          return t.message.toLowerCase().contains(_query.toLowerCase());
        }).toList();
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
                top: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Support', style: AppText.h2(context))
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _SupportCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'WhatsApp',
                    body: '+92 315 0809665',
                    action: () => _launch(whatsappUri),
                    status: 'Connected',
                  ).animate(delay: 60.ms).fadeIn().slideY(begin: .02, end: 0),
                  _SupportCard(
                    icon: Icons.email_rounded,
                    title: 'Email',
                    body: 'farhannaeem@gmail.com',
                    action: () => _launch(emailUri),
                    status: 'Support',
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: .02, end: 0),
                  _SupportCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Instagram',
                    body: '@scopeguard (opens WhatsApp)',
                    action: () => _launch(whatsappUri),
                    status: 'Tap to chat',
                  ).animate(delay: 140.ms).fadeIn().slideY(begin: .02, end: 0),
                ],
              ),
              SizedBox(height: gap),
              _FaqList().animate(delay: 180.ms).fadeIn().slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              Text('Your tickets', style: AppText.h3(context)),
              const SizedBox(height: 8),
              if (tickets.isEmpty)
                const _EmptyTickets()
              else ...[
                AppTextField(
                  controller: _queryController,
                  label: 'Search tickets',
                  icon: Icons.search_rounded,
                  showClear: _query.isNotEmpty,
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_query.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _query = '';
                          _queryController.clear();
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Clear search'),
                    ),
                  ),
                ],
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _EmptyFilteredTickets(),
                  )
                else
                  ...filtered.asMap().entries.map(
                      (e) => _TicketTile(
                        ticket: e.value,
                        dateLabel: _dateFmt.format(e.value.createdAt),
                        onResolve: () => _updateStatus(e.value, 'closed'),
                        onReopen: () => _updateStatus(e.value, 'open'),
                        onDelete: () => _deleteTicket(e.value),
                      )
                          .animate(delay: (40 * e.key).ms)
                          .fadeIn()
                          .slideY(begin: .02, end: 0),
                    ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                controller: _message,
                label: 'Describe your issue',
                icon: Icons.support_agent_rounded,
                maxLines: 3,
                showClear: _message.text.isNotEmpty,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending || _message.text.trim().isEmpty
                      ? null
                      : _submitTicket,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending...' : 'Send ticket'),
                ),
              ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback action;
  final String status;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title(context)),
                const SizedBox(height: 4),
                Text(body, style: AppText.bodyMuted(context)),
                const SizedBox(height: 4),
                Text(status, style: AppText.small(context)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final faqs = const [
    _Faq(
      q: 'How do I mark a request out of scope?',
      a: 'Open the request and toggle the scope switch. It will show up in Requests Hub.',
    ),
    _Faq(
      q: 'Can I export reports to PDF?',
      a: 'Yes, use the Reports hub or client detail screen to generate PDFs.',
    ),
    _Faq(
      q: 'How do I connect Slack?',
      a: 'Go to Integrations and click Connect on the Slack card.',
    ),
  ];

  const _FaqList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: faqs
          .map(
            (f) => ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_rounded),
              title: Text(f.q, style: AppText.title(context)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, bottom: 12),
                  child: Text(f.a, style: AppText.bodyMuted(context)),
                )
              ],
            ),
          )
          .toList(),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _Ticket {
  final String id;
  final String message;
  final String status;
  final DateTime createdAt;

  const _Ticket({
    required this.id,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory _Ticket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return _Ticket(
      id: doc.id,
      message: (data['message'] ?? '').toString(),
      status: (data['status'] ?? 'open').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final _Ticket ticket;
  final VoidCallback onResolve;
  final VoidCallback onReopen;
  final VoidCallback onDelete;
  final String dateLabel;

  const _TicketTile({
    required this.ticket,
    required this.onResolve,
    required this.onReopen,
    required this.onDelete,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = ticket.status == 'open'
        ? AppColors.warning
        : (ticket.status == 'closed' ? AppColors.subtext : AppColors.success);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.support_agent_rounded, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.message, style: AppText.body(context)),
                const SizedBox(height: 4),
                Text(
                  '${ticket.status.toUpperCase()} | $dateLabel',
                  style: AppText.small(context).copyWith(color: color),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'resolve':
                  onResolve();
                  break;
                case 'reopen':
                  onReopen();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'resolve', child: Text('Mark resolved')),
              PopupMenuItem(value: 'reopen', child: Text('Reopen')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.subtext),
          const SizedBox(height: 8),
          Text('No support tickets yet', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Send us a message and we will get back to you.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyFilteredTickets extends StatelessWidget {
  const _EmptyFilteredTickets();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 40, color: AppColors.subtext),
          const SizedBox(height: 8),
          Text('No matching tickets', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            'Try a different search term.',
            style: AppText.bodyMuted(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
