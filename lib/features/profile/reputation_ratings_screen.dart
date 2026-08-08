import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ReputationRatingsScreen extends StatelessWidget {
  const ReputationRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reputation & Ratings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.logoGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Trust Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ Newcomer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete jobs and collaborate to build your reputation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: _buildStatCard('0', 'Jobs\nCompleted', Icons.task_alt_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('0', 'Projects\nJoined', Icons.groups_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('0.0', 'Avg\nRating', Icons.star_outline)),
              ],
            ),
            const SizedBox(height: 24),

            // Milestones
            const Text(
              'Milestones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildMilestoneRow(
              icon: Icons.emoji_events_outlined,
              title: 'First Job Completed',
              subtitle: 'Complete your first job to unlock',
              isUnlocked: false,
            ),
            const SizedBox(height: 8),
            _buildMilestoneRow(
              icon: Icons.verified_outlined,
              title: 'Trusted Collaborator',
              subtitle: 'Complete 5 jobs with a 4+ star rating',
              isUnlocked: false,
            ),
            const SizedBox(height: 8),
            _buildMilestoneRow(
              icon: Icons.rocket_launch_outlined,
              title: 'Rising Star',
              subtitle: 'Reach a trust score of 50',
              isUnlocked: false,
            ),
            const SizedBox(height: 8),
            _buildMilestoneRow(
              icon: Icons.workspace_premium_outlined,
              title: 'Top Contributor',
              subtitle: 'Complete 25 jobs with excellent reviews',
              isUnlocked: false,
            ),
            const SizedBox(height: 24),

            // Recent reviews placeholder
            const Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 40, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Complete your first job to start receiving reviews from collaborators.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFE4F9EE) : const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF1DBF73).withAlpha(40)
                  : Colors.black.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isUnlocked ? const Color(0xFF1DBF73) : Colors.black38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? Colors.black87 : Colors.black54,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock_outline,
            size: 20,
            color: isUnlocked ? const Color(0xFF1DBF73) : Colors.black26,
          ),
        ],
      ),
    );
  }
}
