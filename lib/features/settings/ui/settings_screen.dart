import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/logic/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _scrollController = ScrollController();
  bool _emailAlerts = true;
  bool _pushAlerts = true;
  bool _weeklySummary = true;
  bool _twoFactor = false;
  bool _darkMode = false;
  bool _saving = false;
  String _plan = 'Free';
  bool _loaded = false;
  _SettingsModel _saved = _SettingsModel.fallback();

  bool get _isDirty =>
      _emailAlerts != _saved.emailAlerts ||
      _pushAlerts != _saved.pushAlerts ||
      _weeklySummary != _saved.weeklySummary ||
      _twoFactor != _saved.twoFactor ||
      _darkMode != _saved.darkMode ||
      _plan != _saved.plan;

  Stream<_SettingsModel> _stream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield _SettingsModel.fallback();
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('meta');

    await for (final snap in docRef.snapshots()) {
      if (!snap.exists) {
        await docRef.set(_SettingsModel.fallback().toMap(), SetOptions(merge: true));
        yield _SettingsModel.fallback();
        continue;
      }
      yield _SettingsModel.fromMap(snap.data() ?? {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('meta')
          .set(
        {
          'notifications': {
            'emailAlerts': _emailAlerts,
            'pushAlerts': _pushAlerts,
            'weeklySummary': _weeklySummary,
          },
          'security': {'twoFactor': _twoFactor},
          'appearance': {'darkMode': _darkMode},
          'plan': _plan,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyModel(_SettingsModel data) {
    _emailAlerts = data.emailAlerts;
    _pushAlerts = data.pushAlerts;
    _weeklySummary = data.weeklySummary;
    _twoFactor = data.twoFactor;
    _darkMode = data.darkMode;
    _plan = data.plan;
    _saved = data;
  }

  void _resetToSaved() {
    _applyModel(_saved);
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_SettingsModel>(
      stream: _stream(),
      builder: (context, snap) {
        final data = snap.data ?? _SettingsModel.fallback();
        if (!_loaded || !_isDirty) {
          _applyModel(data);
          _loaded = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              TextButton.icon(
                onPressed: _isDirty ? _resetToSaved : null,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Reset'),
              ),
              TextButton.icon(
                onPressed: _saving || !_isDirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving' : 'Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: Scrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
              _ProfileHeader(plan: _plan)
                  .animate()
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: .04, end: 0),
              const SizedBox(height: 16),
              _PlanCard(plan: _plan, onManage: () => context.go('/billing'))
                  .animate()
                  .fadeIn(delay: 60.ms)
                  .slideY(begin: .04, end: 0),
              const SizedBox(height: 24),
              _Section(title: 'Account'),
              _SettingsTile(
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle: 'Edit name, role, preferences',
                onTap: () => context.go('/profile'),
              ),
              _SettingsTile(
                icon: Icons.lock_rounded,
                title: 'Security',
                subtitle: 'Password & two-factor',
                onTap: () => context.go('/settings/security'),
              ),
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Real-time alerts & reminders',
                trailing: Switch(
                  value: _emailAlerts || _pushAlerts,
                  onChanged: (v) => setState(() {
                    _emailAlerts = v;
                    _pushAlerts = v;
                  }),
                ),
                onTap: () => context.go('/notifications'),
              ),
              const SizedBox(height: 24),
              _Section(title: 'Preferences'),
              SwitchListTile(
                value: _weeklySummary,
                onChanged: (v) => setState(() => _weeklySummary = v),
                title: const Text('Weekly summary emails'),
                subtitle: const Text('Friday recap of scope changes'),
              ),
              SwitchListTile(
                value: _twoFactor,
                onChanged: (v) => setState(() => _twoFactor = v),
                title: const Text('Two-factor login'),
                subtitle: const Text('Add security to your account'),
              ),
              SwitchListTile(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                title: const Text('Dark mode'),
                subtitle: const Text('Store preference (app restart may be required)'),
              ),
              const SizedBox(height: 24),
              _Section(title: 'App & Data'),
              _SettingsTile(
                icon: Icons.extension_rounded,
                title: 'Integrations',
                subtitle: 'Slack, Notion, Jira, Zapier',
                onTap: () => context.go('/integrations'),
              ),
              _SettingsTile(
                icon: Icons.file_upload_rounded,
                title: 'Exports',
                subtitle: 'PDF / CSV exports',
                onTap: () => context.go('/exports'),
              ),
              _SettingsTile(
                icon: Icons.storage_rounded,
                title: 'Data retention',
                subtitle: 'Export schedule and storage policy',
                onTap: () => context.go('/settings/data'),
              ),
              _SettingsTile(
                icon: Icons.notifications_active_rounded,
                title: 'Activity log',
                subtitle: 'Recent actions & changes',
                onTap: () => context.go('/activity'),
              ),
              _SettingsTile(
                icon: Icons.support_agent_rounded,
                title: 'Support',
                subtitle: 'FAQ, live chat, guides',
                onTap: () => context.go('/support'),
              ),
              const SizedBox(height: 24),
              _Section(title: 'Danger'),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out of your account'),
                  onTap: _logout,
                ),
              ).animate().fadeIn(delay: 240.ms).slideY(begin: .04, end: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String plan;
  const _ProfileHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan: $plan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtext),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String plan;
  final VoidCallback onManage;

  const _PlanCard({required this.plan, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan: $plan',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage billing and invoices.',
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtext),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onManage,
              child: const Text('Manage'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.subtext),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsModel {
  final bool emailAlerts;
  final bool pushAlerts;
  final bool weeklySummary;
  final bool twoFactor;
  final bool darkMode;
  final String plan;

  const _SettingsModel({
    required this.emailAlerts,
    required this.pushAlerts,
    required this.weeklySummary,
    required this.twoFactor,
    required this.darkMode,
    required this.plan,
  });

  factory _SettingsModel.fromMap(Map<String, dynamic> data) {
    final n = data['notifications'] as Map<String, dynamic>? ?? {};
    final s = data['security'] as Map<String, dynamic>? ?? {};
    final a = data['appearance'] as Map<String, dynamic>? ?? {};
    return _SettingsModel(
      emailAlerts: (n['emailAlerts'] as bool?) ?? true,
      pushAlerts: (n['pushAlerts'] as bool?) ?? true,
      weeklySummary: (n['weeklySummary'] as bool?) ?? true,
      twoFactor: (s['twoFactor'] as bool?) ?? false,
      darkMode: (a['darkMode'] as bool?) ?? false,
      plan: (data['plan'] ?? 'Free').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': {
        'emailAlerts': emailAlerts,
        'pushAlerts': pushAlerts,
        'weeklySummary': weeklySummary,
      },
      'security': {'twoFactor': twoFactor},
      'appearance': {'darkMode': darkMode},
      'plan': plan,
    };
  }

  factory _SettingsModel.fallback() => const _SettingsModel(
        emailAlerts: true,
        pushAlerts: true,
        weeklySummary: true,
        twoFactor: false,
        darkMode: false,
        plan: 'Free',
      );
}
