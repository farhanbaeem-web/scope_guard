import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../logic/requests_service.dart';

class AddRequestScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const AddRequestScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _cost = TextEditingController();

  bool _inScope = true;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await RequestsService.instance.addRequest(
        clientId: widget.clientId,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        inScope: _inScope,
        estimatedCost: _inScope ? null : int.tryParse(_cost.text.trim()),
      );

      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Request'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_loading ? 'Saving' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.centeredContent(
        context,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: Responsive.bottomSafeSpace(context, extra: 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientName,
                  style: AppText.small(context),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: .03, end: 0),

                const SizedBox(height: 6),

                Text(
                  'New request',
                  style: AppText.h2(context),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                _SectionCard(
                  title: 'Request details',
                  icon: Icons.list_alt_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: Validators.combine([
                          (v) => Validators.required(v, fieldName: 'Title'),
                          (v) =>
                              Validators.maxLength(v, 80, fieldName: 'Title'),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _desc,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.notes_rounded),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => Validators.maxLength(
                          v,
                          400,
                          fieldName: 'Description',
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                _SectionCard(
                  title: 'Scope',
                  icon: Icons.rule_rounded,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _inScope,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _inScope = v),
                        title: Text(
                          _inScope ? 'In scope' : 'Out of scope',
                          style: AppText.title(context),
                        ),
                        subtitle: Text(
                          _inScope
                              ? 'Part of the original agreement.'
                              : 'Extra work that should be billed separately.',
                          style: AppText.subtitle(context),
                        ),
                      ),
                      if (!_inScope) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _cost,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Estimated cost (₹)',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (v) {
                            if (_inScope) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Estimated cost is required';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0)
                              return 'Enter a valid amount';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 140.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_loading ? 'Saving...' : 'Save request'),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.radius(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppText.h3(context))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
