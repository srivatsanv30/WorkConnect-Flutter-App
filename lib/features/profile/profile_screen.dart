import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class ProfileScreen extends StatefulWidget {
  final AppUser? user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppUser? _currentUser;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUser = user;
      });
    }
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    if (_currentUser?.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${_currentUser!.id}');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final currentPassword = currentPasswordController.text.trim();
                      final newPassword = newPasswordController.text.trim();
                      if (currentPassword.isEmpty || newPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                        return;
                      }
                      if (_currentUser == null) return;
                      
                      setDialogState(() => isLoading = true);
                      
                      final result = await AuthService().changePassword(
                        email: _currentUser!.email,
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                      );
                      
                      if (!ctx.mounted) return;
                      setDialogState(() => isLoading = false);
                      
                      if (result['success']) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['errorMessage'] ?? 'Failed to change password')));
                      }
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final name = _currentUser?.name ?? 'Guest';
    final email = _currentUser?.email ?? '';
    final skills = _currentUser?.skills ?? [];
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
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _profileImage == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                if (_currentUser?.title?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                onTap: () async {
                  final updatedUser = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ManageProfileScreen(user: _currentUser))
                  );
                  if (updatedUser != null && updatedUser is AppUser) {
                    setState(() {
                      _currentUser = updatedUser;
                    });
                  }
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
              _MenuRow(
                icon: Icons.password_outlined,
                label: 'Change Password',
                onTap: () => _showChangePasswordDialog(context),
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReputationRatingsScreen(userId: _currentUser?.id)));
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
