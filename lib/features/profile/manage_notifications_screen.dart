import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() => _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _newJobAlerts = true;
  bool _taskUpdates = true;
  bool _mentionAlerts = true;
  bool _weeklyDigest = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.getHeroGradient(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay in the loop',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose what notifications you want to receive.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // General
            _buildSectionTitle('General'),
            SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildToggleRow(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildToggleRow(
                  icon: Icons.email_outlined,
                  label: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildToggleRow(
                  icon: Icons.volume_up_outlined,
                  label: 'Notification Sound',
                  subtitle: 'Play a sound for incoming notifications',
                  value: _soundEnabled,
                  onChanged: (v) => setState(() => _soundEnabled = v),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Activity Alerts
            _buildSectionTitle('Activity Alerts'),
            SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildToggleRow(
                  icon: Icons.work_outline,
                  label: 'New Job Alerts',
                  subtitle: 'When new jobs matching your skills are posted',
                  value: _newJobAlerts,
                  onChanged: (v) => setState(() => _newJobAlerts = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildToggleRow(
                  icon: Icons.task_alt_outlined,
                  label: 'Task Updates',
                  subtitle: 'When tasks assigned to you are updated',
                  value: _taskUpdates,
                  onChanged: (v) => setState(() => _taskUpdates = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildToggleRow(
                  icon: Icons.alternate_email_outlined,
                  label: 'Mentions',
                  subtitle: 'When someone mentions you in a conversation',
                  value: _mentionAlerts,
                  onChanged: (v) => setState(() => _mentionAlerts = v),
                ),
                const Divider(height: 1, indent: 52),
                _buildToggleRow(
                  icon: Icons.summarize_outlined,
                  label: 'Weekly Digest',
                  subtitle: 'A weekly summary of your activity',
                  value: _weeklyDigest,
                  onChanged: (v) => setState(() => _weeklyDigest = v),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Theme.of(context).cardColor, size: 20),
                        SizedBox(width: 10),
                        Text('Notification preferences saved!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1DBF73),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primary),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
