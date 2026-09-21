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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.logoGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Highlighted skills card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.logoGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.psychology_alt_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Skills',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skills.isEmpty ? 'No skills added yet' : skills.join(', '),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Settings Section
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.person_outline,
                label: 'Manage Profile',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageProfileScreen(user: user)));
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

          const SizedBox(height: 24),

          // Support Section
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.emoji_events_outlined,
                label: 'Reputation & Ratings',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReputationRatingsScreen(userId: user?.id)));
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
          
          const SizedBox(height: 32),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.redAccent.withAlpha(100),
            ),
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
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(height: 1, indent: 64, color: Theme.of(context).dividerColor.withAlpha(80)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const iconColor = AppTheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15, 
                  color: Theme.of(context).colorScheme.onSurface, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 16, 
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
            ),
          ],
        ),
      ),
    );
  }
}
