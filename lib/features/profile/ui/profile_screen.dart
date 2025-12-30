import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _role = TextEditingController();
  bool _weekly = true;
  bool _twoFactor = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  Stream<_ProfileData> _stream() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield _ProfileData.fallback();
      return;
    }
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await for (final snap in docRef.snapshots()) {
      if (!snap.exists) {
        await docRef.set(_ProfileData.fallback().toMap(), SetOptions(merge: true));
        yield _ProfileData.fallback();
        continue;
      }
      yield _ProfileData.fromMap(snap.data() ?? {}, user.email ?? '');
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _name.text.trim(),
        'role': _role.text.trim(),
        'prefs': {
          'weeklySummary': _weekly,
          'twoFactor': _twoFactor,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updateDisplayName(_name.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    return StreamBuilder<_ProfileData>(
      stream: _stream(),
      builder: (context, snap) {
        final data = snap.data ?? _ProfileData.fallback();
        _name.text = data.name;
        _role.text = data.role;
        _weekly = data.weeklySummary;
        _twoFactor = data.twoFactor;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: Responsive.bottomSafeSpace(context, extra: 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Profile', style: AppText.h2(context)),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save changes'),
                  ),
                ],
              ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
              SizedBox(height: gap),
              _ProfileHeader(name: data.name, email: data.email)
                  .animate(delay: 60.ms)
                  .fadeIn()
                  .slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              _Section(
                title: 'Personal details',
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_rounded),
                        hintText: data.email,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              _Section(
                title: 'Preferences',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _weekly,
                      title: Text('Weekly summary', style: AppText.title(context)),
                      subtitle: const Text('Email a recap of scope changes every Friday'),
                      onChanged: (v) => setState(() => _weekly = v),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _twoFactor,
                      title: Text('Two-factor login', style: AppText.title(context)),
                      subtitle: const Text('Add an extra layer of security'),
                      onChanged: (v) => setState(() => _twoFactor = v),
                    ),
                  ],
                ),
              ).animate(delay: 140.ms).fadeIn().slideY(begin: .02, end: 0),
              SizedBox(height: gap),
              _Section(
                title: 'Danger zone',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer ownership or deactivate your account.',
                      style: AppText.bodyMuted(context),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.shield_rounded),
                          label: const Text('Transfer ownership'),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                          label: const Text('Deactivate'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 180.ms).fadeIn().slideY(begin: .02, end: 0),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppText.h3(context)),
              const SizedBox(height: 6),
              Text(email, style: AppText.bodyMuted(context)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh avatar'),
          ),
        ],
      ),
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
          Text(title, style: AppText.h3(context)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProfileData {
  final String name;
  final String email;
  final String role;
  final bool weeklySummary;
  final bool twoFactor;

  const _ProfileData({
    required this.name,
    required this.email,
    required this.role,
    required this.weeklySummary,
    required this.twoFactor,
  });

  factory _ProfileData.fromMap(Map<String, dynamic> data, String email) {
    final prefs = data['prefs'] as Map<String, dynamic>? ?? {};
    return _ProfileData(
      name: (data['name'] ?? '').toString().isEmpty ? 'Your name' : data['name'].toString(),
      email: email,
      role: (data['role'] ?? 'Owner').toString(),
      weeklySummary: (prefs['weeklySummary'] as bool?) ?? true,
      twoFactor: (prefs['twoFactor'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'prefs': {
        'weeklySummary': weeklySummary,
        'twoFactor': twoFactor,
      },
    };
  }

  factory _ProfileData.fallback() => const _ProfileData(
        name: 'Scope Guard user',
        email: 'your@email.com',
        role: 'Owner',
        weeklySummary: true,
        twoFactor: false,
      );
}
