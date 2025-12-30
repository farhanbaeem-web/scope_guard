import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/client_model.dart';
import '../logic/clients_service.dart';

class AddEditClientScreen extends StatefulWidget {
  final ClientModel? existing; // null = Add mode, not null = Edit mode

  const AddEditClientScreen({super.key, this.existing});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _name;
  late final TextEditingController _project;
  late final TextEditingController _notes;

  String _contract = 'Fixed Price';
  bool _risky = false;
  late final String _initialName;
  late final String _initialProject;
  late final String _initialNotes;
  late final String _initialContract;
  late final bool _initialRisky;

  bool _loading = false;

  bool get _isEdit => widget.existing != null;
  bool get _isDirty =>
      _name.text != _initialName ||
      _project.text != _initialProject ||
      _notes.text != _initialNotes ||
      _contract != _initialContract ||
      _risky != _initialRisky;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _project = TextEditingController(text: widget.existing?.project ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _contract = widget.existing?.contractType ?? 'Fixed Price';
    _risky = widget.existing?.risky ?? false;
    _initialName = _name.text;
    _initialProject = _project.text;
    _initialNotes = _notes.text;
    _initialContract = _contract;
    _initialRisky = _risky;
  }

  @override
  void dispose() {
    _name.dispose();
    _project.dispose();
    _notes.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_isEdit) {
        await ClientsService.instance.updateClient(
          clientId: widget.existing!.id,
          name: _name.text,
          project: _project.text,
          contractType: _contract,
          notes: _notes.text.trim().isEmpty ? '' : _notes.text,
        );

        await ClientsService.instance.setRisky(
          clientId: widget.existing!.id,
          risky: _risky,
        );
      } else {
        await ClientsService.instance.addClient(
          name: _name.text,
          project: _project.text,
          contractType: _contract,
          notes: _notes.text,
          risky: _risky,
        );
        // Risk + notes can be added later after creation (optional).
        // Keeping MVP safe: no extra write needed on create.
      }

      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _name.text = _initialName;
    _project.text = _initialProject;
    _notes.text = _initialNotes;
    _contract = _initialContract;
    _risky = _initialRisky;
    setState(() {});
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Client' : 'Add Client';

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            TextButton.icon(
              onPressed: _isDirty ? _resetForm : null,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Reset'),
            ),
            TextButton.icon(
              onPressed: _loading || !_isDirty ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
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
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: Responsive.bottomSafeSpace(context, extra: 24),
                ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Client Details',
                  style: AppText.h2(context),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                _SectionCard(
                  title: 'Basics',
                  icon: Icons.person_rounded,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _name,
                        showClear: _name.text.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                        label: 'Client name',
                        icon: Icons.badge_rounded,
                        validator: Validators.combine([
                          (v) =>
                              Validators.required(v, fieldName: 'Client name'),
                          (v) => Validators.maxLength(
                            v,
                            60,
                            fieldName: 'Client name',
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _project,
                        showClear: _project.text.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                        label: 'Project',
                        icon: Icons.work_rounded,
                        validator: Validators.combine([
                          (v) => Validators.required(v, fieldName: 'Project'),
                          (v) =>
                              Validators.maxLength(v, 80, fieldName: 'Project'),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _contract,
                        decoration: const InputDecoration(
                          labelText: 'Contract type',
                          prefixIcon: Icon(Icons.assignment_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Fixed Price',
                            child: Text('Fixed Price'),
                          ),
                          DropdownMenuItem(
                            value: 'Retainer',
                            child: Text('Retainer'),
                          ),
                        ],
                        onChanged: _loading
                            ? null
                            : (v) => setState(
                                () => _contract = v ?? 'Fixed Price',
                              ),
                      ),
                    ],
                    ),
                ).animate().fadeIn(delay: 80.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                _SectionCard(
                  title: 'Internal Notes',
                  icon: Icons.sticky_note_2_rounded,
                  subtitle:
                      'Private notes for you (client expectations, warnings, preferences).',
                  child: AppTextField(
                    controller: _notes,
                    maxLines: 4,
                    label: 'Notes (optional)',
                    icon: Icons.notes_rounded,
                    showClear: _notes.text.isNotEmpty,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        Validators.maxLength(v, 300, fieldName: 'Notes'),
                  ),
                ).animate().fadeIn(delay: 140.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                _SectionCard(
                  title: 'Flags',
                  icon: Icons.flag_rounded,
                  child: SwitchListTile(
                    value: _risky,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _risky = v),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Mark as risky client',
                      style: AppText.title(context),
                    ),
                    subtitle: Text(
                      'Shows warning badge in lists and helps you track scope creep patterns.',
                      style: AppText.subtitle(context),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: .03, end: 0),

                SizedBox(height: Responsive.gap(context, 2)),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading || !_isDirty ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _loading
                          ? 'Saving...'
                          : (_isEdit ? 'Update Client' : 'Create Client'),
                    ),
                  ),
                ).animate().fadeIn(delay: 260.ms),
              ],
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: AppText.bodyMuted(context)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
