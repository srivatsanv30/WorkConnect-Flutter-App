import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../auth/user_model.dart';
import '../auth/auth_service.dart';
import '../auth/auth_screen.dart';
import 'manage_profile_screen.dart';
import 'customize_experience_screen.dart';
import 'manage_notifications_screen.dart';
import 'reputation_ratings_screen.dart';
import 'faq_screen.dart';
import 'report_bug_screen.dart';


class ProfileScreen extends StatelessWidget {
  final AppUser? user;

  const ProfileScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final skills = user?.skills ?? [];
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppTheme.logoGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: Colors.black45, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Highlighted skills card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.logoGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology_alt_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Skills',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        skills.isEmpty ? 'No skills added yet' : skills.join(', '),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.person_outline,
                label: 'Manage Profile',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageProfileScreen()));
                },
              ),
              _MenuRow(
                icon: Icons.tune_outlined,
                label: 'Customize My Experience',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomizeExperienceScreen()));
                },
              ),
              _MenuRow(
                icon: Icons.notifications_none_outlined,
                label: 'Manage Notifications',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageNotificationsScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.emoji_events_outlined,
                label: 'Reputation & Ratings',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReputationRatingsScreen()));
                },
              ),
              _MenuRow(
                icon: Icons.help_outline,
                label: 'FAQ',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FAQScreen()));
                },
              ),
              _MenuRow(
                icon: Icons.bug_report_outlined,
                label: 'Report a Bug',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportBugScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.logout,
                label: 'Sign Out',
                iconColor: Colors.red,
                labelColor: Colors.red,
                showChevron: false,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 56, color: Color(0xFFEDEDF5)),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppTheme.primary,
    this.labelColor = Colors.black87,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500),
              ),
            ),
            if (showChevron)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}