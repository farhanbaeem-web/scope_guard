import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  Stream<_BillingModel> _stream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield _BillingModel.fallback();
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('billing').doc('meta');

    await for (final snap in docRef.snapshots()) {
      if (!snap.exists) {
        await docRef.set(_BillingModel.fallback().toMap());
        yield _BillingModel.fallback();
        continue;
      }
      yield _BillingModel.fromMap(snap.data() ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    return StreamBuilder<_BillingModel>(
      stream: _stream(),
      builder: (context, snap) {
        final data = snap.data ?? _BillingModel.fallback();
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: Responsive.bottomSafeSpace(context, extra: 32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 720;
                  final title = Text('Billing', style: AppText.h2(context));
                  final actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/billing/subscription'),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text('Subscription'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/billing/invoices'),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Invoices'),
                      ),
                    ],
                  );
                  return isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 8),
                            actions,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: title),
                            actions,
                          ],
                        );
                },
              ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
              SizedBox(height: gap),
              _HeroCard(plan: data.plan, nextInvoice: data.nextInvoice).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
              SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _MetricCard(
                    label: 'Active plan',
                    value: data.plan,
                    icon: Icons.workspace_premium_rounded,
                    accent: AppColors.primary,
                  ),
                  _MetricCard(
                    label: 'Seats in use',
                    value: '${data.seatsUsed} / ${data.seatsTotal}',
                    icon: Icons.group_rounded,
                    accent: AppColors.info,
                  ),
                  _MetricCard(
                    label: 'Next invoice',
                    value: data.nextInvoice,
                    icon: Icons.receipt_long_rounded,
                    accent: AppColors.success,
                  ),
                ],
              ).animate(delay: 80.ms).fadeIn().slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              _Section(
                title: 'Payment methods',
                child: Column(
                  children: [
                    for (int i = 0; i < data.paymentMethods.length; i++) ...[
                      _PaymentTile(
                        brand: data.paymentMethods[i].brand,
                        note: data.paymentMethods[i].note,
                        icon: Icons.credit_card_rounded,
                        primary: data.paymentMethods[i].primary,
                      ),
                      if (i != data.paymentMethods.length - 1) const SizedBox(height: 10),
                    ],
                    if (data.paymentMethods.isEmpty)
                      const Text('No payment methods yet', style: TextStyle(color: AppColors.subtext)),
                  ],
                ),
              ).animate(delay: 130.ms).fadeIn().slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              _Section(
                title: 'Invoices',
                child: Column(
                  children: [
                    for (final inv in data.invoices)
                      _InvoiceRow(month: inv.month, amount: inv.amount, status: inv.status),
                    if (data.invoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No invoices yet', style: TextStyle(color: AppColors.subtext)),
                      ),
                  ],
                ),
              ).animate(delay: 170.ms).fadeIn().slideY(begin: .02, end: 0),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String plan;
  final String nextInvoice;

  const _HeroCard({required this.plan, required this.nextInvoice});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final content = [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 32),
          ),
          SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stripe billing', style: AppText.h3(context).copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Plan: $plan · Next: $nextInvoice',
                    style: AppText.bodyMuted(context).copyWith(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(width: isNarrow ? 0 : 12, height: isNarrow ? 12 : 0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link_rounded),
                label: const Text('Connect Stripe'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export invoices'),
              ),
            ],
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                )
              : Row(children: content),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 280 ? double.infinity : 260.0;
        return SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.small(context)),
                      const SizedBox(height: 4),
                      Text(value, style: AppText.title(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppText.h3(context)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String brand;
  final String note;
  final IconData icon;
  final bool primary;

  const _PaymentTile({
    required this.brand,
    required this.note,
    required this.icon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = primary ? AppColors.success : AppColors.subtext;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: ListTile(
        leading: Icon(icon, color: badgeColor),
        title: Text(brand),
        subtitle: Text(note),
        trailing: primary
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PRIMARY',
                  style: AppText.chip(context).copyWith(color: badgeColor),
                ),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String month;
  final String amount;
  final String status;

  const _InvoiceRow({
    required this.month,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(month, style: AppText.body(context))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: AppText.chip(context).copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(amount, style: AppText.title(context)),
        ],
      ),
    );
  }
}

class _BillingModel {
  final String plan;
  final String nextInvoice;
  final int seatsUsed;
  final int seatsTotal;
  final List<_PaymentMethod> paymentMethods;
  final List<_Invoice> invoices;

  const _BillingModel({
    required this.plan,
    required this.nextInvoice,
    required this.seatsUsed,
    required this.seatsTotal,
    required this.paymentMethods,
    required this.invoices,
  });

  factory _BillingModel.fromMap(Map<String, dynamic> data) {
    final pm = (data['paymentMethods'] as List<dynamic>? ?? [])
        .map((e) => _PaymentMethod.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final inv = (data['invoices'] as List<dynamic>? ?? [])
        .map((e) => _Invoice.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _BillingModel(
      plan: (data['plan'] ?? 'Pro').toString(),
      nextInvoice: (data['nextInvoice'] ?? '\$38.00').toString(),
      seatsUsed: (data['seatsUsed'] as num?)?.toInt() ?? 1,
      seatsTotal: (data['seatsTotal'] as num?)?.toInt() ?? 3,
      paymentMethods: pm,
      invoices: inv,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'nextInvoice': nextInvoice,
      'seatsUsed': seatsUsed,
      'seatsTotal': seatsTotal,
      'paymentMethods': paymentMethods.map((e) => e.toMap()).toList(),
      'invoices': invoices.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static _BillingModel fallback() {
    return _BillingModel(
      plan: 'Pro (trial)',
      nextInvoice: '\$38.00',
      seatsUsed: 1,
      seatsTotal: 3,
      paymentMethods: const [
        _PaymentMethod(brand: 'Visa •••• 4242', note: 'Primary · Expires 04/28', primary: true),
        _PaymentMethod(brand: 'Mastercard •••• 1010', note: 'Backup · Expires 11/27', primary: false),
      ],
      invoices: const [
        _Invoice(month: 'Jan 2025', amount: '\$38.00', status: 'Paid'),
        _Invoice(month: 'Dec 2024', amount: '\$38.00', status: 'Paid'),
        _Invoice(month: 'Nov 2024', amount: '\$24.00', status: 'Paid'),
      ],
    );
  }
}

class _PaymentMethod {
  final String brand;
  final String note;
  final bool primary;
  const _PaymentMethod({required this.brand, required this.note, required this.primary});

  factory _PaymentMethod.fromMap(Map<String, dynamic> data) => _PaymentMethod(
        brand: (data['brand'] ?? '').toString(),
        note: (data['note'] ?? '').toString(),
        primary: (data['primary'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {'brand': brand, 'note': note, 'primary': primary};
}

class _Invoice {
  final String month;
  final String amount;
  final String status;
  const _Invoice({required this.month, required this.amount, required this.status});

  factory _Invoice.fromMap(Map<String, dynamic> data) => _Invoice(
        month: (data['month'] ?? '').toString(),
        amount: (data['amount'] ?? '').toString(),
        status: (data['status'] ?? '').toString(),
      );

  Map<String, dynamic> toMap() => {'month': month, 'amount': amount, 'status': status};
}
