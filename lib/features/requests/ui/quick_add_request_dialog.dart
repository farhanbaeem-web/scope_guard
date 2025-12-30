import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:scope_guard/features/requests/logic/requests_service.dart';

import '../../../../core/platform/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/validators.dart';

/// Premium quick add request (modal dialog)
/// - Safe on all platforms
/// - No overflow
/// - Uses RequestsService (keeps Firestore logic out of UI)
Future<void> showQuickAddRequest(BuildContext context, String clientId) async {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final desc = TextEditingController();
  final cost = TextEditingController();

  bool inScope = true;
  bool saving = false;

  await showDialog(
    context: context,
    barrierDismissible: !saving,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> save() async {
            FocusScope.of(ctx).unfocus();
            if (!formKey.currentState!.validate()) return;

            setState(() => saving = true);
            try {
              await RequestsService.instance.addRequest(
                clientId: clientId,
                title: title.text.trim(),
                description: desc.text.trim(),
                inScope: inScope,
                estimatedCost: inScope ? null : int.tryParse(cost.text.trim()),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Request added')));
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed: $e')));
            } finally {
              if (ctx.mounted) setState(() => saving = false);
            }
          }

          // ✅ FIXED: Used contentMaxWidth with a clamp to fix the undefined method error
          final maxW = Responsive.contentMaxWidth(context).clamp(0.0, 500.0);

          return Dialog(
                insetPadding: const EdgeInsets.all(16),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.radius(context),
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Quick add request',
                                  style: AppText.h3(context),
                                ),
                              ),
                              IconButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log scope creep instantly while talking to a client.',
                            style: AppText.bodyMuted(context),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: title,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.title_rounded),
                            ),
                            validator: Validators.combine([
                              (v) => Validators.required(v, fieldName: 'Title'),
                              (v) => Validators.maxLength(
                                v,
                                80,
                                fieldName: 'Title',
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: desc,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                            validator: (v) => Validators.maxLength(
                              v,
                              240,
                              fieldName: 'Description',
                            ),
                          ),
                          const SizedBox(height: 12),

                          SwitchListTile(
                            value: inScope,
                            contentPadding: EdgeInsets.zero,
                            onChanged: saving
                                ? null
                                : (v) => setState(() => inScope = v),
                            title: Text(
                              inScope ? 'In scope' : 'Out of scope',
                              style: AppText.title(context),
                            ),
                            subtitle: Text(
                              inScope
                                  ? 'Part of the original agreement.'
                                  : 'Extra work that should be billed.',
                              style: AppText.subtitle(context),
                            ),
                          ),

                          if (!inScope) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: cost,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Estimated cost (₹)',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              validator: (v) {
                                if (inScope) return null;
                                if (v == null || v.trim().isEmpty)
                                  return 'Cost is required';
                                final n = int.tryParse(v.trim());
                                if (n == null || n < 0)
                                  return 'Enter a valid amount';
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: saving ? null : save,
                                  icon: saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.add_rounded),
                                  label: Text(saving ? 'Adding...' : 'Add'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 180.ms)
              .scale(begin: const Offset(.98, .98), end: const Offset(1, 1));
        },
      );
    },
  );

  title.dispose();
  desc.dispose();
  cost.dispose();
}
