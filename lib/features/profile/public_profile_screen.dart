import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../auth/user_model.dart';

class PublicProfileScreen extends StatelessWidget {
  final AppUser user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.name.isNotEmpty ? user.name : 'Unknown User';
    final email = user.email;
    final skills = user.skills;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text('Applicant Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.logoGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (email.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'XP Obtained', user.xp.toString(), Icons.star_border)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, 'Projects', user.projectsCompleted.toString(), Icons.check_circle_outline)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Score', user.ratingAverage.toStringAsFixed(1), Icons.bar_chart)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, 'Reviews', user.ratingCount.toString(), Icons.rate_review_outlined)),
              ],
            ),
            SizedBox(height: 32),
            if (skills.isNotEmpty) ...[
              Text(
                'Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((s) => Chip(
                  label: Text(s),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
            SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user_outlined, color: AppTheme.primary),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WorkConnect Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Verified applicant ready to collaborate.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
