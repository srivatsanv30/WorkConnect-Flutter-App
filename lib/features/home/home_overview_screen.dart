import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class HomeOverviewScreen extends StatelessWidget {
  final String userName;
  final ValueChanged<int> onNavigate;

  const HomeOverviewScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✨ WELCOME, ${userName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Collaborate, Assign,\nTrack & Build',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'WorkConnect is a hybrid workspace bridging project management, '
                  'remote mentorship, and real-time collaboration. Structure tasks, '
                  'get AI guidance, and build together.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => onNavigate(1),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'Enter Workspace Hub',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => onNavigate(2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  child: const Text(
                    'Post a Project',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Core Platform Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.psychology_alt_outlined,
            iconColor: AppTheme.primary,
            iconBg: const Color(0xFFEDEBFB),
            title: 'AI-Powered Workflow Breakdown',
            description:
                'Type any project idea and AI automatically generates the '
                'milestones, required skills, and duration targets.',
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.desktop_windows_outlined,
            iconColor: const Color(0xFF00A9E0),
            iconBg: const Color(0xFFE3F6FD),
            title: 'Live Visual Guidance Mode',
            description:
                'Share your screen remotely and allow mentors or teammates '
                'to give live guidance and resolve blockers together.',
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF1DBF73),
            iconBg: const Color(0xFFE4F9EE),
            title: 'Reputation & Completion Score',
            description:
                'Every completed job builds your trust score, so you can '
                'showcase verified experience across your projects.',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.black54, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
