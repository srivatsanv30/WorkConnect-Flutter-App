import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../auth/user_model.dart';

class PublicProfileScreen extends StatelessWidget {
  final AppUser user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.name.isNotEmpty ? user.name : 'Unknown User';
    final title = user.title.isNotEmpty ? user.title : 'Professional';
    final email = user.email;
    final skills = user.skills;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Applicant Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header and Avatar Stack
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Gradient Background Header
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F88C6), Color(0xFF26B6C1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -30,
                        child: CircleAvatar(
                          radius: 90,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -20,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Overlapping Avatar
                Positioned(
                  bottom: -60,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Spacer to account for the overlapping avatar
            const SizedBox(height: 70),
            
            // Rest of the profile content
            Column(
              children: [
                // Name and Title
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildStatItem(context, 'XP', user.xp.toString(), Icons.military_tech_rounded, Colors.amber.shade600)),
                        _buildDivider(context),
                        Expanded(child: _buildStatItem(context, 'Projects', user.projectsCompleted.toString(), Icons.task_alt_rounded, const Color(0xFF1DBF73))),
                        _buildDivider(context),
                        Expanded(child: _buildStatItem(context, 'Rating', user.ratingAverage.toStringAsFixed(1), Icons.star_rounded, Colors.orange)),
                        _buildDivider(context),
                        Expanded(child: _buildStatItem(context, 'Reviews', user.ratingCount.toString(), Icons.rate_review_rounded, const Color(0xFF0F88C6))),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Skills Section
                if (skills.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expertise & Skills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            children: skills.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
                
                // Verified Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? const [Color(0xFF161B22), Color(0xFF2D333B)]
                            : [AppTheme.primary.withValues(alpha: 0.05), AppTheme.primary.withValues(alpha: 0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.15)
                              : AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.verified, color: AppTheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WorkConnect Verified',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Identity and qualifications verified. Ready to collaborate.',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
